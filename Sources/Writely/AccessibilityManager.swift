import Foundation
import ApplicationServices
import AppKit

struct CaptureTarget {
    let element: AXUIElement
    let appName: String
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
    
    func captureSelectedText() -> CaptureTarget? {
        let apps = NSWorkspace.shared.runningApplications
        var targetApp: NSRunningApplication?
        
        // 1. First, look for the frontmost app that ISN'T Writely
        // When clicking a menu bar icon, the previous app often still has focus
        for app in apps {
            if app.bundleIdentifier != "com.antonkulikov.writely" && app.isActive {
                targetApp = app
                break
            }
        }
        
        // 2. Fallback: Look for any recently active app (ignoring background/hidden processes)
        if targetApp == nil {
            // Sort by launch date or just pick the first visible non-Writely app
            targetApp = apps.filter { $0.bundleIdentifier != "com.antonkulikov.writely" && !$0.isHidden && $0.activationPolicy == .regular }.first
        }
        
        guard let finalApp = targetApp else {
            print("Writely: Error - Could not identify a target application to read from.")
            return nil
        }
        
        print("Writely: Attempting capture from \(finalApp.localizedName ?? "Unknown App") (\(finalApp.bundleIdentifier ?? "no-id"))")
        
        let appElement = AXUIElementCreateApplication(finalApp.processIdentifier)
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement as! AXUIElement? else {
            print("Writely: Could not find focused element in \(finalApp.localizedName ?? "app")")
            return nil
        }
        
        // Try AX first
        var selectedText: AnyObject?
        let textResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
        
        if textResult == .success, let text = selectedText as? String, !text.isEmpty {
            return CaptureTarget(element: element, appName: finalApp.localizedName ?? "Active App", selectedText: text)
        }
        
        // Fallback: Simulate Cmd+C
        // We MUST ensure the target app stays frontmost for Cmd+C to work
        print("Writely: AX failed, trying Clipboard fallback for \(finalApp.localizedName ?? "app")...")
        
        let originalClipboard = NSPasteboard.general.string(forType: .string)
        simulateCopy()
        
        // Delay for clipboard synchronization
        Thread.sleep(forTimeInterval: 0.2)
        
        if let text = NSPasteboard.general.string(forType: .string), !text.isEmpty && text != originalClipboard {
            return CaptureTarget(element: element, appName: finalApp.localizedName ?? "Active App", selectedText: text)
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
    
    func replaceText(in element: AXUIElement, with correctedText: String) -> Bool {
        // Try AX first
        let writeResult = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, correctedText as CFString)
        
        if writeResult == .success {
            return true
        }
        
        // Fallback: Paste
        print("Writely: AX Write failed, trying Paste fallback...")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(correctedText, forType: .string)
        
        // Give macOS a moment to restore focus to target app
        Thread.sleep(forTimeInterval: 0.1)
        simulatePaste()
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
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func getActiveAppName() -> String {
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            return frontmostApp.localizedName ?? "Active App"
        }
        return "Unknown App"
    }
}
