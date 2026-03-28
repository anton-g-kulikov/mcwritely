import SwiftUI
import AppKit

class CorrectionPanel: NSPanel {
    init(contentView: NSView, size: CGSize = CorrectionPanelLayout.windowSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            // Non-activating so Electron apps keep the selection even while the panel is visible/clicked.
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.isFloatingPanel = true
        // Hotkey capture in some Electron apps causes focus to bounce back to the originating app.
        // Keep the panel visible so users can still see the error/output instead of a "blink then close".
        self.hidesOnDeactivate = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.contentView = contentView
    }
    
    override var canBecomeKey: Bool {
        // Don't become key; keep the target app active so selection isn't lost before Apply.
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
