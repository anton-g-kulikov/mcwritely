import Cocoa
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()
    
    // Core callback for the hotkey action
    private var onTrigger: ((CaptureTarget?) -> Void)?
    
    // Store refs for cleanup
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    private init() {}
    
    func startMonitoring(onTrigger: @escaping (CaptureTarget?) -> Void) {
        self.onTrigger = onTrigger
        
        // Carbon HotKey Registration
        
        // 1. Signature
        // We pick an arbitrary 4-char code for our signature.
        // 'McWr' in hex: 0x4D635772
        let hotKeyID = EventHotKeyID(signature: 0x4D635772, id: 1)
        
        // 2. Modifiers: Cmd + Option + Shift
        // In Carbon: cmdKey (256), optionKey (2048), shiftKey (512)
        // Note: We use the Carbon constants
        let modifiers = UInt32(cmdKey | optionKey | shiftKey)
        
        // 3. KeyCode for 'G' is 5
        let keyCode = UInt32(5)
        
        // 4. Register
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        
        guard status == noErr else {
            print("McWritely: Failed to register Carbon hotkey. Status: \(status)")
            return
        }
        self.hotKeyRef = ref
        
        // 5. Install Handler
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { (handler, event, userData) -> OSStatus in
                // Recover 'self' context
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                
                manager.handleHotKeyPress()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        
        if handlerStatus == noErr {
            print("McWritely: Carbon Hotkey registered (Cmd+Opt+Shift+G). Input Monitoring not required.")
        } else {
            print("McWritely: Failed to install Carbon event handler: \(handlerStatus)")
        }
    }
    
    private func handleHotKeyPress() {
        print("McWritely: Hotkey triggered!")
        let preferredApp = NSWorkspace.shared.frontmostApplication
        Task { @MainActor in
            let target = await AccessibilityManager.shared.captureSelectedText(preferredApp: preferredApp)
            self.onTrigger?(target)
        }
    }
    
    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
