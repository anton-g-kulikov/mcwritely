import SwiftUI

struct CorrectionView: View {
    @ObservedObject var viewModel: CorrectionViewModel

    private var panelState: CorrectionPanelState {
        CorrectionPanelState(
            correctedText: viewModel.correctedText,
            originalText: viewModel.originalText,
            isProcessing: viewModel.isProcessing,
            errorMessage: viewModel.errorMessage
        )
    }

    private var showsApplySuggestion: Bool {
        panelState.showsApplySuggestion
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Improve your text")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                }
            }
            
            if let error = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    if error.contains("Permission") {
                        Button("Open Settings & Request Access") {
                            _ = AccessibilityManager.shared.checkPermissions(prompt: true)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            
            if !viewModel.originalText.isEmpty || !viewModel.correctedText.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Result area
                    if showsApplySuggestion {
                        TextEditor(text: .constant(viewModel.correctedText))
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.primary)
                            .scrollContentBackground(.hidden)
                            .lineSpacing(4)
                            .padding(8)
                            .frame(height: CorrectionPanelLayout.resultAreaHeight(for: viewModel.correctedText))
                            .background(Color.blue.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                            )
                    } else if viewModel.isProcessing {
                        Text(viewModel.originalText)
                            .blur(radius: 2)
                            .opacity(0.5)
                            .frame(maxWidth: .infinity, minHeight: CorrectionPanelLayout.loadingPreviewHeight(for: viewModel.originalText), alignment: .leading)
                            .padding(12)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Text("Select text and press")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        KeycapView(text: "⇧")
                        KeycapView(text: "⌥")
                        KeycapView(text: "⌘")
                        KeycapView(text: "G")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
            
            Divider()
            
            VStack(spacing: 4) {
                if showsApplySuggestion {
                    NativeActionButton(
                        title: "Apply Suggestion",
                        systemImageName: nil,
                        isPrimary: true,
                        minimumHeight: 42,
                        fontSize: 15
                    ) {
                        Task {
                            await viewModel.applyCorrection()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                NativeActionButton(
                    title: "Close",
                    systemImageName: nil,
                    isPrimary: false,
                    minimumHeight: 28,
                    fontSize: 13
                ) {
                    viewModel.reset()
                    PanelManager.shared.hide()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .frame(
            minWidth: CorrectionPanelLayout.contentWidth,
            idealWidth: CorrectionPanelLayout.contentWidth,
            maxWidth: CorrectionPanelLayout.contentWidth,
            minHeight: CorrectionPanelLayout.contentHeight(for: panelState),
            alignment: .top
        )
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 28, x: 0, y: 14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(CorrectionPanelLayout.outerPadding) // Outer padding for shadow clearance
        .onReceive(NotificationCenter.default.publisher(for: .triggerCorrection)) { notification in
            if let context = notification.object as? TriggerCorrectionContext {
                if let target = context.capturedTarget {
                    startChecking(target: target)
                } else {
                    viewModel.showCaptureFailure(preferredApp: context.preferredApp)
                }
                return
            }

            if let target = notification.object as? CaptureTarget {
                startChecking(target: target)
                return
            }

            if let app = notification.object as? NSRunningApplication {
                startChecking(preferredApp: app)
                return
            }

            // No-op: don’t auto-capture on open; require an explicit trigger.
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetCorrectionUI)) { _ in
            viewModel.reset()
        }
    }
    
    private func startChecking(target: CaptureTarget? = nil, preferredApp: NSRunningApplication? = nil) {
        Task {
            await viewModel.processSelection(preCapturedTarget: target, preferredApp: preferredApp)
        }
    }
}

struct KeycapView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(.title3, design: .rounded))
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.08))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
    }
}
