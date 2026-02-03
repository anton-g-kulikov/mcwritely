import SwiftUI

struct CorrectionView: View {
    @ObservedObject var viewModel: CorrectionViewModel
    
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
                    if !viewModel.correctedText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            TextEditor(text: .constant(viewModel.correctedText))
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.primary)
                                .scrollContentBackground(.hidden)
                                .lineSpacing(4)
                                .padding(8)
                                .frame(minHeight: 100, maxHeight: 300)
                                .background(Color.blue.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                                )
                            
                            Button(action: {
                                PanelManager.shared.hide()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    viewModel.applyCorrection()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Apply Suggestion")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .controlSize(.large)
                        }
                    } else if viewModel.isProcessing {
                        Text(viewModel.originalText)
                            .blur(radius: 2)
                            .opacity(0.5)
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
            
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.originalText = ""
                    viewModel.correctedText = ""
                    PanelManager.shared.hide()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Close")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 420) // Slightly wider for multiline text
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(20) // Outer padding for shadow clearance
        .onAppear {
            if !viewModel.isProcessing && !viewModel.originalText.isEmpty {
                // Already have text, maybe continue?
            } else {
                startChecking()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerCorrection"))) { notification in
            if let target = notification.object as? CaptureTarget {
                startChecking(target: target)
            } else {
                startChecking()
            }
        }
    }
    
    private func startChecking(target: CaptureTarget? = nil) {
        Task {
            await viewModel.processSelection(preCapturedTarget: target)
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
