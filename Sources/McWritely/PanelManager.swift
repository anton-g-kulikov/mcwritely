import SwiftUI
import AppKit
import Combine

class PanelManager {
    static let shared = PanelManager()
    
    private var panel: CorrectionPanel?
    private var viewModel: CorrectionViewModel?
    private var hostingView: NSHostingView<CorrectionView>?
    private var cancellables = Set<AnyCancellable>()
    
    func setup(viewModel: CorrectionViewModel) {
        self.viewModel = viewModel
        cancellables.removeAll()
        
        let initialState = panelState(for: viewModel)
        let initialSize = CorrectionPanelLayout.windowSize(for: initialState)
        let hostingView = NSHostingView(rootView: CorrectionView(viewModel: viewModel))
        hostingView.frame = NSRect(origin: .zero, size: initialSize)
        self.hostingView = hostingView
        
        let panel = CorrectionPanel(contentView: hostingView, size: initialSize)
        panel.center()
        self.panel = panel

        Publishers.CombineLatest4(
            viewModel.$correctedText,
            viewModel.$originalText,
            viewModel.$isProcessing,
            viewModel.$errorMessage
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] correctedText, originalText, isProcessing, errorMessage in
            let state = CorrectionPanelState(
                correctedText: correctedText,
                originalText: originalText,
                isProcessing: isProcessing,
                errorMessage: errorMessage
            )
            self?.resizePanel(for: state)
        }
        .store(in: &cancellables)
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

    private func resizePanel(for state: CorrectionPanelState) {
        guard let panel, let hostingView else { return }

        let size = CorrectionPanelLayout.windowSize(for: state)
        let currentFrame = panel.frame
        let nextOrigin = NSPoint(
            x: currentFrame.midX - (size.width / 2),
            y: currentFrame.midY - (size.height / 2)
        )

        hostingView.frame = NSRect(origin: .zero, size: size)
        panel.setFrame(NSRect(origin: nextOrigin, size: size), display: true)
    }

    private func panelState(for viewModel: CorrectionViewModel) -> CorrectionPanelState {
        CorrectionPanelState(
            correctedText: viewModel.correctedText,
            originalText: viewModel.originalText,
            isProcessing: viewModel.isProcessing,
            errorMessage: viewModel.errorMessage
        )
    }
}
