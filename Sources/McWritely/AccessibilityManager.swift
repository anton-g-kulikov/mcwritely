import Foundation
import ApplicationServices
import AppKit

struct CaptureTarget {
    let element: AXUIElement
    let appName: String
    let appPID: pid_t
    let bundleIdentifier: String?
    let selectedText: String
    let selectedTextRange: NSRange?
}

class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    private init() {}
    
    func checkPermissions(prompt: Bool = false) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            return AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
        return AXIsProcessTrusted()
    }
    

    
    @MainActor
    func captureSelectedText(preferredApp: NSRunningApplication? = nil) async -> CaptureTarget? {
        let mcwritelyBundleID = Bundle.main.bundleIdentifier ?? "com.antonkulikov.mcwritely"

        // Prefer an explicit app (from hotkey time) to avoid the “McWritely is frontmost” trap.
        var targetApp = preferredApp
        if targetApp?.bundleIdentifier == mcwritelyBundleID {
            targetApp = nil
        }

        // Next best: the current frontmost app.
        if targetApp == nil {
            let frontmost = NSWorkspace.shared.frontmostApplication
            if frontmost?.bundleIdentifier != mcwritelyBundleID {
                targetApp = frontmost
            }
        }

        // Menu bar / panel interaction case: use last known non-McWritely app.
        if targetApp == nil {
            targetApp = AppFocusTracker.shared.lastNonMcWritelyApp()
        }

        // Final fallback: any visible regular app.
        if targetApp == nil {
            targetApp = NSWorkspace.shared.runningApplications.first {
                $0.bundleIdentifier != mcwritelyBundleID && !$0.isHidden && $0.activationPolicy == .regular
            }
        }
        
        guard let finalApp = targetApp else {
            print("McWritely: Error - Could not identify a target application to read from.")
            return nil
        }
        
        _ = await ensureAppIsFrontmost(finalApp)
        
        print("McWritely: Attempting capture from \(finalApp.localizedName ?? "Unknown App") (\(finalApp.bundleIdentifier ?? "no-id"))")
        
        let appElement = AXUIElementCreateApplication(finalApp.processIdentifier)
        let focused = readFocusedAXElement(from: appElement) ?? readFocusedAXElement(from: AXUIElementCreateSystemWide())
        let elementForTarget = focused ?? appElement

        // Try AX first: in Electron/webviews the focused element often does not expose selection attributes.
        // Walk up the parent chain and attempt multiple AX strategies (selectedText, stringForRange, value+range).
        if let focused, let found = captureFromElementOrAncestors(focused) {
            return CaptureTarget(
                element: found.element,
                appName: finalApp.localizedName ?? "Active App",
                appPID: finalApp.processIdentifier,
                bundleIdentifier: finalApp.bundleIdentifier,
                selectedText: found.text,
                selectedTextRange: found.range
            )
        }
        
        // Fallback: Simulate Cmd+C
        // We MUST ensure the target app stays frontmost for Cmd+C to work
        print("McWritely: AX failed, trying Clipboard fallback for \(finalApp.localizedName ?? "app")...")
        
        let pasteboard = NSPasteboard.general
        let originalItems = snapshotPasteboardItems(pasteboard)
        _ = await ensureAppIsFrontmost(finalApp)
        let marker = "MCWR_COPY_MARKER_\(UUID().uuidString)"
        pasteboard.clearContents()
        pasteboard.setString(marker, forType: .string)
        _ = pasteboard.changeCount

        // Give Electron apps a moment after hotkey handling before issuing copy.
        try? await Task.sleep(nanoseconds: 120_000_000)

        // Try accessibility menu copy first (if available), then key-chord injection.
        performMenuCopy(appPID: finalApp.processIdentifier)
        simulateCopy(appPID: finalApp.processIdentifier)

        defer { restorePasteboardItems(pasteboard, items: originalItems) }

        // Wait for the pasteboard to actually change. Electron-style apps can be slower under load.
        let maxAttempts = 20
        for attempt in 0..<maxAttempts {
            try? await Task.sleep(nanoseconds: 120_000_000)

            // If copy never happened, pasteboard may remain our marker.
            let plain = PasteboardTextExtractor.plainText(from: pasteboard)
            if let plain, plain != marker {
                return CaptureTarget(
                    element: elementForTarget,
                    appName: finalApp.localizedName ?? "Active App",
                    appPID: finalApp.processIdentifier,
                    bundleIdentifier: finalApp.bundleIdentifier,
                    selectedText: plain,
                    selectedTextRange: focused.flatMap { readAXRange($0, attribute: kAXSelectedTextRangeAttribute as CFString) }
                )
            }

            // Retry copy a couple of times; some Electron editors ignore the first injected command.
            if attempt == 4 || attempt == 10 {
                _ = await ensureAppIsFrontmost(finalApp)
                performMenuCopy(appPID: finalApp.processIdentifier)
                simulateCopy(appPID: finalApp.processIdentifier)
            }
        }
        
        return nil
    }

    private func simulateCopy(appPID: pid_t) {
        // Some Electron apps behave better when we post only the "C" key with an explicit .maskCommand flag
        // (rather than sending a separate Command key down/up sequence).
        let source = CGEventSource(stateID: .hidSystemState) ?? CGEventSource(stateID: .combinedSessionState)
        let cKey: CGKeyCode = 0x08 // 'C'

        postModifiedKeyPress(source: source, virtualKey: cKey, flags: .maskCommand) { ev in
            ev.postToPid(appPID)
        }

        // Fallback taps for apps that ignore postToPid.
        postModifiedKeyPress(source: source, virtualKey: cKey, flags: .maskCommand) { ev in
            ev.post(tap: .cghidEventTap)
        }
        postModifiedKeyPress(source: source, virtualKey: cKey, flags: .maskCommand) { ev in
            ev.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    private func performMenuCopy(appPID: pid_t) {
        let app = AXUIElementCreateApplication(appPID)
        var menubarObj: AnyObject?
        let res = AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute as CFString, &menubarObj)
        guard res == .success, let menubarObj else { return }
        let ref = menubarObj as CFTypeRef
        guard CFGetTypeID(ref) == AXUIElementGetTypeID() else { return }
        let menubar = unsafeBitCast(menubarObj, to: AXUIElement.self)

        // Find all menu items with cmdChar == "c" and choose the best candidate.
        // This avoids pressing the wrong "c" item (Copy Style, Copy Link, etc).
        var candidates: [AXMenuCopyCandidate] = []
        collectMenuCopyCandidates(root: menubar, into: &candidates, limit: 5000)
        if candidates.isEmpty { return }

        let indexed = candidates.enumerated().map { (candidate: $0.element.candidate, index: $0.offset) }
        guard let (_, idx) = MenuCopyCandidateSelector.chooseBest(from: indexed) else { return }
        _ = AXUIElementPerformAction(candidates[idx].element, kAXPressAction as CFString)
    }

    private struct AXMenuCopyCandidate {
        let element: AXUIElement
        let candidate: MenuCopyCandidate
    }

    private func collectMenuCopyCandidates(root: AXUIElement, into out: inout [AXMenuCopyCandidate], limit: Int) {
        if out.count >= limit { return }

        var childrenObj: AnyObject?
        let res = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenObj)
        guard res == .success, let children = childrenObj as? [AnyObject] else { return }

        for child in children {
            let childRef = child as CFTypeRef
            if CFGetTypeID(childRef) != AXUIElementGetTypeID() { continue }
            let el = unsafeBitCast(child, to: AXUIElement.self)

            let cmdChar = readAXString(el, attribute: kAXMenuItemCmdCharAttribute as CFString)
            let cmdModifiers = readAXInt(el, attribute: kAXMenuItemCmdModifiersAttribute as CFString)
            let title = readAXString(el, attribute: kAXTitleAttribute as CFString)
            let enabled = readAXBool(el, attribute: kAXEnabledAttribute as CFString)

            if let cmdChar, cmdChar.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "c" {
                out.append(AXMenuCopyCandidate(
                    element: el,
                    candidate: MenuCopyCandidate(title: title, cmdChar: cmdChar, cmdModifiers: cmdModifiers, enabled: enabled)
                ))
            }

            collectMenuCopyCandidates(root: el, into: &out, limit: limit)
        }
    }

    private func readFocusedAXElement(from container: AXUIElement) -> AXUIElement? {
        var focusedObj: AnyObject?
        let result = AXUIElementCopyAttributeValue(container, kAXFocusedUIElementAttribute as CFString, &focusedObj)
        guard result == .success, let focusedObj else { return nil }
        let ref = focusedObj as CFTypeRef
        guard CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(focusedObj, to: AXUIElement.self)
    }

    private func postModifiedKeyPress(source: CGEventSource?, virtualKey: CGKeyCode, flags: CGEventFlags, post: (CGEvent) -> Void) {
        guard
            let down = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true),
            let up = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false)
        else { return }

        down.flags = flags
        up.flags = flags

        post(down)
        usleep(5_000)
        post(up)
    }
    
    private func captureFromElementOrAncestors(_ element: AXUIElement, maxDepth: Int = 12) -> (element: AXUIElement, text: String, range: NSRange?)? {
        var current: AXUIElement? = element
        var depth = 0

        while let el = current, depth <= maxDepth {
            if let resolved = resolveSelectedText(for: el) {
                return (element: el, text: resolved.text, range: resolved.range)
            }
            current = readAXElement(el, attribute: kAXParentAttribute as CFString)
            depth += 1
        }

        return nil
    }

    private func resolveSelectedText(for element: AXUIElement) -> (text: String, range: NSRange?)? {
        let selectedText = readAXString(element, attribute: kAXSelectedTextAttribute as CFString)
        let range = readAXRange(element, attribute: kAXSelectedTextRangeAttribute as CFString)

        // Parameterized range-based extraction works in some apps even when kAXSelectedText is missing.
        let stringForRange: String? = {
            guard let range else { return nil }
            return readAXStringForRange(element, range: range)
        }()

        let value = readAXString(element, attribute: kAXValueAttribute as CFString)

        guard let resolved = SelectionTextResolver.resolve(
            selectedText: selectedText,
            stringForRange: stringForRange,
            value: value,
            selectedRange: range
        ) else {
            return nil
        }

        return (text: resolved, range: range)
    }

    private func readAXStringForRange(_ element: AXUIElement, range: NSRange) -> String? {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let rangeValue = AXValueCreate(.cfRange, &cfRange) else { return nil }

        var out: AnyObject?
        if AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &out
        ) == .success {
            if let s = out as? String {
                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            if let a = out as? NSAttributedString {
                let trimmed = a.string.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
        }

        out = nil
        if AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXAttributedStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &out
        ) == .success, let a = out as? NSAttributedString {
            let trimmed = a.string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }

    private func readAXElement(_ element: AXUIElement, attribute: CFString) -> AXUIElement? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let value else { return nil }
        let ref = value as CFTypeRef
        guard CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXUIElement.self)
    }
    
    @MainActor
    func replaceText(in target: CaptureTarget, with correctedText: String) async -> ReplacementResult {
        // Always keep corrected text on clipboard so users can manually paste if replacement fails.
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(correctedText, forType: .string)
        
        // Try AX first
        // ENSURE frontmost before AX write too, not just paste
        guard await ensureTargetAppFrontmost(target) else {
            print("McWritely: Target app not frontmost, replacement cancelled.")
            return ReplacementResult(method: nil, state: .failed, detail: "Target app is not focused. Click back into the target app and try Apply again.")
        }
        
        // Strategy A: Replace within kAXValue using the selected text range.
        if let range = readAXRange(target.element, attribute: kAXSelectedTextRangeAttribute as CFString) ?? target.selectedTextRange,
           let value = readAXString(target.element, attribute: kAXValueAttribute as CFString),
           let newValue = StringRangeReplacer.replacing(in: value, range: range, with: correctedText) {
            let valueWrite = AXUIElementSetAttributeValue(target.element, kAXValueAttribute as CFString, newValue as CFString)
            if valueWrite == .success {
                let selected = readAXString(target.element, attribute: kAXSelectedTextAttribute as CFString)
                let updatedValue = readAXString(target.element, attribute: kAXValueAttribute as CFString)
                if ReplacementVerifier.isVerified(selectedText: selected, value: updatedValue, correctedText: correctedText) {
                    return ReplacementResult(method: .axValueRange, state: .verified, detail: nil)
                }
                return ReplacementResult(
                    method: .axValueRange,
                    state: .unverified,
                    detail: "McWritely attempted to apply the text but could not verify it in this app. The corrected text is on your clipboard; you can paste it manually if needed."
                )
            }
        }

        // Strategy B: Try setting selected text directly (works in some apps).
        let writeResult = AXUIElementSetAttributeValue(target.element, kAXSelectedTextAttribute as CFString, correctedText as CFString)
        if writeResult == .success {
            print("McWritely: AX Write reported success.")
            let selected = readAXString(target.element, attribute: kAXSelectedTextAttribute as CFString)
            let value = readAXString(target.element, attribute: kAXValueAttribute as CFString)
            if ReplacementVerifier.isVerified(selectedText: selected, value: value, correctedText: correctedText) {
                return ReplacementResult(method: .axSelectedText, state: .verified, detail: nil)
            }
            return ReplacementResult(
                method: .axSelectedText,
                state: .unverified,
                detail: "McWritely attempted to apply the text but could not verify it in this app. The corrected text is on your clipboard; you can paste it manually if needed."
            )
        }
        
        // Fallback: Paste
        print("McWritely: AX Write failed or unreliable, trying Paste fallback...")
        guard await ensureTargetAppFrontmost(target) else {
            print("McWritely: Target app not frontmost, paste cancelled.")
            return ReplacementResult(method: .paste, state: .failed, detail: "Target app is not focused. Click back into the target app and try Apply again.")
        }
        
        // Give macOS a moment to restore focus to target app
        try? await Task.sleep(nanoseconds: 200_000_000)
        simulatePaste()
        
        // Retry paste once after re-activating, for apps that ignore the first Cmd+V
        try? await Task.sleep(nanoseconds: 200_000_000)
        if await ensureTargetAppFrontmost(target) {
            simulatePaste()
        }

        // Best-effort verification.
        try? await Task.sleep(nanoseconds: 250_000_000)
        let selected = readAXString(target.element, attribute: kAXSelectedTextAttribute as CFString)
        let value = readAXString(target.element, attribute: kAXValueAttribute as CFString)
        if ReplacementVerifier.isVerified(selectedText: selected, value: value, correctedText: correctedText) {
            return ReplacementResult(method: .paste, state: .verified, detail: nil)
        }

        // Some apps (Notion/webviews) replace the underlying accessibility element during paste,
        // making the original element unreadable even though paste succeeded.
        // Try to re-capture the (still selected) text and verify against that.
        if let app = NSRunningApplication(processIdentifier: target.appPID) {
            if let recaptured = await captureSelectedText(preferredApp: app),
               ReplacementVerifier.isVerified(selectedText: recaptured.selectedText, value: nil, correctedText: correctedText) {
                return ReplacementResult(method: .paste, state: .verified, detail: nil)
            }
        }

        return ReplacementResult(
            method: .paste,
            state: .unverified,
            detail: "McWritely attempted to paste the corrected text but could not verify the result in this app. The corrected text is on your clipboard; paste it manually if needed."
        )
    }
    
    private func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // 0x09 is 'V'
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        cmdUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cgAnnotatedSessionEventTap)
        cmdUp?.post(tap: .cgAnnotatedSessionEventTap)
    }

    private func readAXString(_ element: AXUIElement, attribute: CFString) -> String? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else { return nil }
        return value as? String
    }

    private func readAXBool(_ element: AXUIElement, attribute: CFString) -> Bool? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let value else { return nil }
        if let b = value as? Bool { return b }
        if let n = value as? NSNumber { return n.boolValue }
        return nil
    }

    private func readAXInt(_ element: AXUIElement, attribute: CFString) -> Int? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let value else { return nil }
        if let n = value as? NSNumber { return n.intValue }
        return nil
    }

    private func readAXRange(_ element: AXUIElement, attribute: CFString) -> NSRange? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let value else { return nil }
        let ref = value as CFTypeRef
        guard CFGetTypeID(ref) == AXValueGetTypeID() else { return nil }
        let axValue = unsafeBitCast(value, to: AXValue.self)

        var cfRange = CFRange()
        guard AXValueGetValue(axValue, .cfRange, &cfRange) else { return nil }
        if cfRange.location < 0 || cfRange.length < 0 { return nil }
        return NSRange(location: cfRange.location, length: cfRange.length)
    }
    
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    

    
    private func getActiveAppName() -> String {
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            return frontmostApp.localizedName ?? "Active App"
        }
        return "Unknown App"
    }
    
    private func isTargetAppFrontmost(_ target: CaptureTarget) -> Bool {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        return frontmost.processIdentifier == target.appPID
    }
    
    @MainActor
    private func ensureTargetAppFrontmost(_ target: CaptureTarget) async -> Bool {
        if isTargetAppFrontmost(target) {
            return true
        }
        guard let app = NSRunningApplication(processIdentifier: target.appPID) else {
            return false
        }
        return await ensureAppIsFrontmost(app)
    }
    
    @MainActor
    private func ensureAppIsFrontmost(_ app: NSRunningApplication) async -> Bool {
        if app.isActive {
            return true
        }
        let activated = app.activate(options: [.activateAllWindows])
        if activated {
            try? await Task.sleep(nanoseconds: 150_000_000)
            return app.isActive
        }
        return false
    }
    
    private func snapshotPasteboardItems(_ pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        guard let items = pasteboard.pasteboardItems else { return [] }
        return items.compactMap { item in
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            return newItem
        }
    }
    
    private func restorePasteboardItems(_ pasteboard: NSPasteboard, items: [NSPasteboardItem]) {
        pasteboard.clearContents()
        if !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }
}
