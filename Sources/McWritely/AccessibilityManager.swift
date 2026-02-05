import Foundation
import ApplicationServices
import AppKit

struct CaptureTarget {
    let element: AXUIElement
    let appName: String
    let appPID: pid_t
    let bundleIdentifier: String?
    let selectedText: String
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
    func captureSelectedText() async -> CaptureTarget? {
        let apps = NSWorkspace.shared.runningApplications
        var targetApp: NSRunningApplication?
        
        // 1. First, look for the frontmost app that ISN'T Writely
        // When clicking a menu bar icon, the previous app often still has focus
        for app in apps {
            if app.bundleIdentifier != "com.antonkulikov.mcwritely" && app.isActive {
                targetApp = app
                break
            }
        }
        
        // 2. Fallback: Look for any recently active app (ignoring background/hidden processes)
        if targetApp == nil {
            // Sort by launch date or just pick the first visible non-Writely app
            targetApp = apps.filter { $0.bundleIdentifier != "com.antonkulikov.mcwritely" && !$0.isHidden && $0.activationPolicy == .regular }.first
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
            return CaptureTarget(
                element: axElement,
                appName: finalApp.localizedName ?? "Active App",
                appPID: finalApp.processIdentifier,
                bundleIdentifier: finalApp.bundleIdentifier,
                selectedText: text
            )
        }
        
        // Fallback: Simulate Cmd+C
        // We MUST ensure the target app stays frontmost for Cmd+C to work
        print("McWritely: AX failed, trying Clipboard fallback for \(finalApp.localizedName ?? "app")...")
        
        let pasteboard = NSPasteboard.general
        let originalItems = snapshotPasteboardItems(pasteboard)
        let originalChangeCount = pasteboard.changeCount
        _ = await ensureAppIsFrontmost(finalApp)
        simulateCopy()
        
        // Delay for clipboard synchronization
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        defer {
            restorePasteboardItems(pasteboard, items: originalItems)
        }
        
        let newChangeCount = pasteboard.changeCount
        guard newChangeCount != originalChangeCount else {
            return nil
        }
        
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return CaptureTarget(
                element: axElement,
                appName: finalApp.localizedName ?? "Active App",
                appPID: finalApp.processIdentifier,
                bundleIdentifier: finalApp.bundleIdentifier,
                selectedText: text
            )
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
    
    @MainActor
    func replaceText(in target: CaptureTarget, with correctedText: String) async -> Bool {
        // ALWAYS handle clipboard if settings request it, or if we anticipate AX failure
        let shouldKeepInClipboard = Settings.shared.keepNewTextInClipboard
        
        // Try AX first
        let writeResult = AXUIElementSetAttributeValue(target.element, kAXSelectedTextAttribute as CFString, correctedText as CFString)
        let axSuccess = (writeResult == .success)
        
        if axSuccess {
            print("McWritely: AX Write reported success.")
            // Even if AX succeeds, we might need to update clipboard
            if shouldKeepInClipboard {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(correctedText, forType: .string)
            }
            return true
        }
        
        // Fallback: Paste
        print("McWritely: AX Write failed or unreliable, trying Paste fallback...")
        guard await ensureTargetAppFrontmost(target) else {
            print("McWritely: Target app not frontmost, paste cancelled.")
            return false
        }
        
        let pasteboard = NSPasteboard.general
        let originalItems = snapshotPasteboardItems(pasteboard)
        
        pasteboard.clearContents()
        pasteboard.setString(correctedText, forType: .string)
        
        // Give macOS a moment to restore focus to target app
        try? await Task.sleep(nanoseconds: 200_000_000)
        simulatePaste()
        
        // Retry paste once after re-activating, for apps that ignore the first Cmd+V
        try? await Task.sleep(nanoseconds: 200_000_000)
        if await ensureTargetAppFrontmost(target) {
            simulatePaste()
        }

        if !shouldKeepInClipboard {
            // Give time for the app to process the paste before restoring clipboard
            try? await Task.sleep(nanoseconds: 300_000_000)
            restorePasteboardItems(pasteboard, items: originalItems)
        }
        return true
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
