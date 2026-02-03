import Foundation
import AppKit

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var monitor: Any?
    
    private init() {}
    
    func startMonitoring(onTrigger: @escaping (CaptureTarget?) -> Void) {
        // Shift + Option + Cmd + G
        // Modifiers: command (1 << 20), option (1 << 19), shift (1 << 17)
        // Key code for 'G' is 5
        
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let expectedModifiers: NSEvent.ModifierFlags = [.command, .option, .shift]
            
            if modifiers == expectedModifiers && event.keyCode == 5 {
                DispatchQueue.main.async {
                    // Start capture immediately while target app still has focus
                    if let target = AccessibilityManager.shared.captureSelectedText() {
                        onTrigger(target)
                    } else {
                        // Still trigger to show the error in the popover
                        onTrigger(nil)
                    }
                }
            }
        }
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
