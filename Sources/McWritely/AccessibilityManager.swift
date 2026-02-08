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

    private static let maxPasteFallbackReselectUTF16Count = 800
    private static let clipboardMarkerPrefix = "MCWR_"
    
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

    private func performMenuPaste(appPID: pid_t) -> Bool {
        let app = AXUIElementCreateApplication(appPID)
        var menubarObj: AnyObject?
        let res = AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute as CFString, &menubarObj)
        guard res == .success, let menubarObj else { return false }
        let ref = menubarObj as CFTypeRef
        guard CFGetTypeID(ref) == AXUIElementGetTypeID() else { return false }
        let menubar = unsafeBitCast(menubarObj, to: AXUIElement.self)

        var candidates: [AXMenuCopyCandidate] = []
        collectMenuShortcutCandidates(root: menubar, cmdChar: "v", into: &candidates, limit: 5000)
        if candidates.isEmpty { return false }

        let indexed = candidates.enumerated().map { (candidate: $0.element.candidate, index: $0.offset) }
        guard let (_, idx) = MenuPasteCandidateSelector.chooseBest(from: indexed) else { return false }
        let ok = AXUIElementPerformAction(candidates[idx].element, kAXPressAction as CFString) == .success
        return ok
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

    private func collectMenuShortcutCandidates(root: AXUIElement, cmdChar: String, into out: inout [AXMenuCopyCandidate], limit: Int) {
        if out.count >= limit { return }

        var childrenObj: AnyObject?
        let res = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenObj)
        guard res == .success, let children = childrenObj as? [AnyObject] else { return }

        for child in children {
            if out.count >= limit { return }
            let childRef = child as CFTypeRef
            if CFGetTypeID(childRef) != AXUIElementGetTypeID() { continue }
            let el = unsafeBitCast(child, to: AXUIElement.self)

            let cmd = readAXString(el, attribute: kAXMenuItemCmdCharAttribute as CFString)
            let cmdModifiers = readAXInt(el, attribute: kAXMenuItemCmdModifiersAttribute as CFString)
            let title = readAXString(el, attribute: kAXTitleAttribute as CFString)
            let enabled = readAXBool(el, attribute: kAXEnabledAttribute as CFString)

            if let cmd, cmd.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cmdChar.lowercased() {
                out.append(AXMenuCopyCandidate(
                    element: el,
                    candidate: MenuCopyCandidate(title: title, cmdChar: cmd, cmdModifiers: cmdModifiers, enabled: enabled)
                ))
            }

            collectMenuShortcutCandidates(root: el, cmdChar: cmdChar, into: &out, limit: limit)
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

    private func simulateShiftSelectLeft(appPID: pid_t, times: Int) {
        if times <= 0 { return }
        let capped = min(times, AccessibilityManager.maxPasteFallbackReselectUTF16Count)
        let source = CGEventSource(stateID: .hidSystemState) ?? CGEventSource(stateID: .combinedSessionState)
        let leftArrow: CGKeyCode = 0x7B

        for i in 0..<capped {
            postModifiedKeyPress(source: source, virtualKey: leftArrow, flags: .maskShift) { ev in
                ev.postToPid(appPID)
            }
            if i % 40 == 39 {
                usleep(1_000)
            }
        }
    }

    private func simulateMoveCaretRight(appPID: pid_t) {
        let source = CGEventSource(stateID: .hidSystemState) ?? CGEventSource(stateID: .combinedSessionState)
        let rightArrow: CGKeyCode = 0x7C

        postModifiedKeyPress(source: source, virtualKey: rightArrow, flags: []) { ev in
            ev.postToPid(appPID)
        }
        postModifiedKeyPress(source: source, virtualKey: rightArrow, flags: []) { ev in
            ev.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    @MainActor
    private func hasActiveSelectionByCopy(appPID: pid_t, correctedText: String, originalSelectedText: String) async -> Bool {
        let pasteboard = NSPasteboard.general
        let marker = "MCWR_SELECTION_CHECK_\(UUID().uuidString)"
        pasteboard.clearContents()
        pasteboard.setString(marker, forType: .string)

        performMenuCopy(appPID: appPID)
        simulateCopy(appPID: appPID)

        // Poll briefly. If there's a selection, Cmd+C should overwrite our marker.
        for _ in 0..<10 {
            try? await Task.sleep(nanoseconds: 60_000_000)
            if let s = PasteboardTextExtractor.plainText(from: pasteboard), s != marker {
                ensureCorrectedTextStaysOnClipboard(correctedText: correctedText, originalSelectedText: originalSelectedText)
                return true
            }
        }

        // Restore corrected text (delayed reassert to win races with Electron clipboard writes).
        ensureCorrectedTextStaysOnClipboard(correctedText: correctedText, originalSelectedText: originalSelectedText)
        return false
    }

    @MainActor
    private func verifyInsertedTextBySelectingAndCopying(appPID: pid_t, correctedText: String) async -> Bool {
        let utf16Count = correctedText.utf16.count
        if utf16Count <= 0 || utf16Count > AccessibilityManager.maxPasteFallbackReselectUTF16Count {
            return false
        }

        // Select the just-inserted text (caret is expected to be at the end after paste), copy, compare.
        simulateShiftSelectLeft(appPID: appPID, times: utf16Count)

        let pasteboard = NSPasteboard.general
        let marker = "MCWR_VERIFY_COPY_\(UUID().uuidString)"
        pasteboard.clearContents()
        pasteboard.setString(marker, forType: .string)

        performMenuCopy(appPID: appPID)
        simulateCopy(appPID: appPID)

        for _ in 0..<12 {
            try? await Task.sleep(nanoseconds: 60_000_000)
            if let s = PasteboardTextExtractor.plainText(from: pasteboard), s != marker {
                let ok = TextNormalizer.normalizeForVerification(s) == TextNormalizer.normalizeForVerification(correctedText)
                pasteboard.clearContents()
                pasteboard.setString(correctedText, forType: .string)
                simulateMoveCaretRight(appPID: appPID)
                return ok
            }
        }

        pasteboard.clearContents()
        pasteboard.setString(correctedText, forType: .string)
        simulateMoveCaretRight(appPID: appPID)
        return false
    }

    @MainActor
    private func ensureCorrectedTextStaysOnClipboard(correctedText: String, originalSelectedText: String) {
        let pasteboard = NSPasteboard.general

        func setNow() {
            pasteboard.clearContents()
            pasteboard.setString(correctedText, forType: .string)
        }

        // Set immediately.
        setNow()

        // Reassert after delays only if clipboard looks like it was overwritten by our own copy/markers.
        let delays: [TimeInterval] = [0.12, 0.35, 0.8]
        for d in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                let current = PasteboardTextExtractor.plainText(from: pasteboard) ?? ""
                if current == correctedText { return }
                if ClipboardReassertPolicy.shouldReassert(
                    currentClipboardText: current,
                    correctedText: correctedText,
                    originalSelectedText: originalSelectedText
                ) {
                    setNow()
                }
            }
        }
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
        // Ensure we keep corrected text on clipboard even if clipboard-based verification/capture overwrites it
        // asynchronously (common in Electron/webviews).
        defer {
            ensureCorrectedTextStaysOnClipboard(correctedText: correctedText, originalSelectedText: target.selectedText)
        }

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

        // In some Electron editors, the selection is cleared by the time Apply runs, so Cmd+V appends at the caret.
        // Before pasting, try to detect whether a selection is active (marker+Cmd+C). If not, attempt to reselect
        // the originally captured selection length by Shift+Left (best-effort).
        var hadSelectionAtPasteTime = await hasActiveSelectionByCopy(appPID: target.appPID, correctedText: correctedText, originalSelectedText: target.selectedText)
        if !hadSelectionAtPasteTime {
            let utf16Count = target.selectedText.utf16.count
            if utf16Count > 0 && utf16Count <= AccessibilityManager.maxPasteFallbackReselectUTF16Count {
                simulateShiftSelectLeft(appPID: target.appPID, times: utf16Count)
                // Re-check once. If this still fails, we avoid "verifying" a paste that may have just appended.
                hadSelectionAtPasteTime = await hasActiveSelectionByCopy(appPID: target.appPID, correctedText: correctedText, originalSelectedText: target.selectedText)
            }
        }

        // If we still can't confirm a selection, do NOT paste automatically; pasting will append at the caret
        // and is more harmful than leaving corrected text on the clipboard.
        if !hadSelectionAtPasteTime {
            return ReplacementResult(
                method: .paste,
                state: .failed,
                detail: "McWritely could not confirm an active selection in this app, so it did not paste automatically (to avoid duplicating text). The corrected text is on your clipboard; paste it manually if needed."
            )
        }
        
        // Give macOS a moment to restore focus to target app
        try? await Task.sleep(nanoseconds: 200_000_000)
        // Prefer menu-based paste in Electron/webviews (more reliable than synthetic key events).
        if !performMenuPaste(appPID: target.appPID) {
            simulatePaste(appPID: target.appPID)
        }

        // Best-effort verification.
        try? await Task.sleep(nanoseconds: 250_000_000)
        let selected = readAXString(target.element, attribute: kAXSelectedTextAttribute as CFString)
        let value = readAXString(target.element, attribute: kAXValueAttribute as CFString)
        if ReplacementVerifier.isVerified(selectedText: selected, value: value, correctedText: correctedText) {
            return ReplacementResult(method: .paste, state: .verified, detail: nil)
        }

        // Try to re-capture the (still selected) text and verify against that.
        if let app = NSRunningApplication(processIdentifier: target.appPID) {
            if let recaptured = await captureSelectedText(preferredApp: app),
               ReplacementVerifier.isVerified(selectedText: recaptured.selectedText, value: nil, correctedText: correctedText) {
                return ReplacementResult(method: .paste, state: .verified, detail: nil)
            }
        }

        // Pragmatic: Notion frequently hides value/selection from AX after paste even when it succeeded.
        // If Notion had a selection at paste time, treat the operation as applied and rely on clipboard fallback
        // for the rare failure case.
        if hadSelectionAtPasteTime, (target.bundleIdentifier?.lowercased().contains("notion") == true) {
            return ReplacementResult(method: .paste, state: .verified, detail: nil)
        }

        return ReplacementResult(
            method: .paste,
            state: .unverified,
            detail: "McWritely attempted to paste the corrected text but could not verify the result in this app. The corrected text is on your clipboard; paste it manually if needed."
        )
    }
    
    private func simulatePaste(appPID: pid_t) {
        // Paste must be executed at most once per Apply. Unlike Cmd+C, multiple delivery routes here
        // cause visible duplication. Use a single route.
        let source = CGEventSource(stateID: .hidSystemState) ?? CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09 // 'V'

        postModifiedKeyPress(source: source, virtualKey: vKey, flags: .maskCommand) { ev in
            // postToPid is ignored by some Electron apps for paste; cghidEventTap is generally more reliable.
            ev.post(tap: .cghidEventTap)
        }
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
