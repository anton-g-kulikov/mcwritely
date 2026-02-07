import SwiftUI

@main
struct McWritelyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        // 1. Utility Menu Bar Icon
        MenuBarExtra("McWritely", systemImage: "pencil.and.outline") {
            VStack(spacing: 0) {
                Button("Open McWritely") {
                    PanelManager.shared.show()
                    NotificationCenter.default.post(name: .resetCorrectionUI, object: nil)
                }
                .padding()
                
                Divider()
                
                HStack {
                    Button("Settings...") {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "settings")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                    
                    Spacer()
                    
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
            }
            .frame(width: 250)
            .buttonStyle(.plain)
        }
        .menuBarExtraStyle(.window)
        
        // 2. Settings Window
        Window("McWritely Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let viewModel = CorrectionViewModel()
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Force the OS to recognize the app immediately
        NSApp.setActivationPolicy(.prohibited)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppFocusTracker.shared.start()

        // Initialize Panel
        PanelManager.shared.setup(viewModel: viewModel)
        
        // Start monitoring early
        HotkeyManager.shared.startMonitoring { target in
            // Capture target and notify UI
            NotificationCenter.default.post(
                name: .triggerCorrection,
                object: target
            )
            
            // Show panel immediately and bring to front
            DispatchQueue.main.async {
                PanelManager.shared.show()
            }
        }
        
        print("McWritely: App fully launched and monitoring.")
    }
}
