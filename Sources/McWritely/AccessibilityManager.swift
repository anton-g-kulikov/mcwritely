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
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            print("McWritely: Could not find focused element in \(finalApp.localizedName ?? "app")")
            return nil
        }
        
        let elementRef = element as CFTypeRef
        guard CFGetTypeID(elementRef) == AXUIElementGetTypeID() else {
            print("McWritely: Focused element is not an AXUIElement in \(finalApp.localizedName ?? "app")")
            return nil
        }
        let axElement = unsafeBitCast(element, to: AXUIElement.self)
        
        // Try AX first
        var selectedText: AnyObject?
        let textResult = AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selectedText)
        
        if textResult == .success, let text = selectedText as? String, !text.isEmpty {
            let range = readAXRange(axElement, attribute: kAXSelectedTextRangeAttribute as CFString)
            return CaptureTarget(
                element: axElement,
                appName: finalApp.localizedName ?? "Active App",
                appPID: finalApp.processIdentifier,
                bundleIdentifier: finalApp.bundleIdentifier,
                selectedText: text,
                selectedTextRange: range
            )
        }

        // Some apps don't expose kAXSelectedText but do expose kAXValue + selection range.
        if let value = readAXString(axElement, attribute: kAXValueAttribute as CFString),
           let range = readAXRange(axElement, attribute: kAXSelectedTextRangeAttribute as CFString),
           let extracted = StringRangeExtractor.substring(in: value, range: range) {
            return CaptureTarget(
                element: axElement,
                appName: finalApp.localizedName ?? "Active App",
                appPID: finalApp.processIdentifier,
                bundleIdentifier: finalApp.bundleIdentifier,
                selectedText: extracted,
                selectedTextRange: range
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
        let markerChangeCount = pasteboard.changeCount

        simulateCopy()

        defer { restorePasteboardItems(pasteboard, items: originalItems) }

        // Wait for the pasteboard to actually change. Electron-style apps can be slower under load.
        let maxAttempts = 10
        for attempt in 0..<maxAttempts {
            try? await Task.sleep(nanoseconds: 120_000_000)

            // If copy never happened, pasteboard may remain our marker.
            let plain = PasteboardTextExtractor.plainText(from: pasteboard)
            let changed = pasteboard.changeCount != markerChangeCount
            if changed, let plain, plain != marker {
                return CaptureTarget(
                    element: axElement,
                    appName: finalApp.localizedName ?? "Active App",
                    appPID: finalApp.processIdentifier,
                    bundleIdentifier: finalApp.bundleIdentifier,
                    selectedText: plain,
                    selectedTextRange: readAXRange(axElement, attribute: kAXSelectedTextRangeAttribute as CFString)
                )
            }

            // Midway, try an accessibility menu-based Copy as a fallback (helps when CGEvent is ignored).
            if attempt == 4 {
                _ = await ensureAppIsFrontmost(finalApp)
                performMenuCopy(appPID: finalApp.processIdentifier)
            }
        }
        
        return nil
    }
    
    private func simulateCopy() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // 0x08 is 'C'
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        cmdUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cgAnnotatedSessionEventTap)
        cmdUp?.post(tap: .cgAnnotatedSessionEventTap)
    }

    private func performMenuCopy(appPID: pid_t) {
        let app = AXUIElementCreateApplication(appPID)
        var menubarObj: AnyObject?
        let res = AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute as CFString, &menubarObj)
        guard res == .success, let menubarObj else { return }
        let ref = menubarObj as CFTypeRef
        guard CFGetTypeID(ref) == AXUIElementGetTypeID() else { return }
        let menubar = unsafeBitCast(menubarObj, to: AXUIElement.self)

        // Find a menu item with cmdChar == "c" (avoids localization issues).
        if let copyItem = findMenuItemByCmdChar(root: menubar, cmdChar: "c") {
            _ = AXUIElementPerformAction(copyItem, kAXPressAction as CFString)
        }
    }

    private func findMenuItemByCmdChar(root: AXUIElement, cmdChar: String) -> AXUIElement? {
        var childrenObj: AnyObject?
        let res = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenObj)
        guard res == .success, let children = childrenObj as? [AnyObject] else { return nil }

        for child in children {
            let childRef = child as CFTypeRef
            if CFGetTypeID(childRef) != AXUIElementGetTypeID() { continue }
            let el = unsafeBitCast(child, to: AXUIElement.self)

            var cmdObj: AnyObject?
            if AXUIElementCopyAttributeValue(el, kAXMenuItemCmdCharAttribute as CFString, &cmdObj) == .success,
               let s = cmdObj as? String,
               s.lowercased() == cmdChar.lowercased() {
                return el
            }

            if let found = findMenuItemByCmdChar(root: el, cmdChar: cmdChar) {
                return found
            }
        }

        return nil
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
