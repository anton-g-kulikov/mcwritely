import SwiftUI
import AppKit

class PanelManager {
    static let shared = PanelManager()
    
    private var panel: CorrectionPanel?
    private var viewModel: CorrectionViewModel?
    
    func setup(viewModel: CorrectionViewModel) {
        self.viewModel = viewModel
        
        let hostingView = NSHostingView(rootView: CorrectionView(viewModel: viewModel))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 350)
        
        let panel = CorrectionPanel(contentView: hostingView)
        panel.center()
        self.panel = panel
    }
    
    func show(activating: Bool = true) {
        guard let panel = panel else { return }
        
        panel.center()
        if activating {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        } else {
            // Show without activating the app. This is important for Electron editors where activation
            // clears the selection, causing Apply (Cmd+V) to append instead of replace.
            panel.orderFrontRegardless()
        }
    }
    
    func hide() {
        panel?.orderOut(nil)
        NSApp.hide(nil)
    }
}
