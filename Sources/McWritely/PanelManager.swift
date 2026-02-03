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
    
    func show() {
        guard let panel = panel else { return }
        
        NSApp.activate(ignoringOtherApps: true)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }
    
    func hide() {
        panel?.orderOut(nil)
    }
}
