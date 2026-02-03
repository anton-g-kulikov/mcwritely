import Foundation
import AppKit

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var monitor: Any?
    
    private init() {}
    
    func startMonitoring(onTrigger: @escaping (CaptureTarget?) -> Void) {
        if !AccessibilityManager.shared.checkInputMonitoringPermissions() {
            print("McWritely: Input Monitoring permission not granted. Hotkey may not work.")
        }
        
        // Shift + Option + Cmd + G
        // Modifiers: command (1 << 20), option (1 << 19), shift (1 << 17)
        // Key code for 'G' is 5
        
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let expectedModifiers: NSEvent.ModifierFlags = [.command, .option, .shift]
            
            if modifiers == expectedModifiers && event.keyCode == 5 {
                Task { @MainActor in
                    let target = await AccessibilityManager.shared.captureSelectedText()
                    onTrigger(target)
                }
            }
        }
        
        if monitor == nil {
            print("McWritely: Failed to register global hotkey monitor.")
        }
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
