import Foundation
import SwiftUI
import Combine

class CorrectionViewModel: ObservableObject {
    @Published var originalText: String = ""
    @Published var correctedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var currentTarget: CaptureTarget? = nil
    
    private var aiService: OpenAIService?
    private var cancellables = Set<AnyCancellable>()
    private var processNonce = UUID()
    
    init() {
        updateService(for: Settings.shared.apiKey)
        
        Settings.shared.$apiKey
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newKey in
                self?.updateService(for: newKey)
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func processSelection(preCapturedTarget: CaptureTarget? = nil, preferredApp: NSRunningApplication? = nil) async {
        let nonce = UUID()
        processNonce = nonce
        self.errorMessage = nil
        self.isProcessing = false
        
        // 1. Check Permissions first
        if !AccessibilityManager.shared.checkPermissions() {
            self.errorMessage = "Accessibility Permission Required. Please click the icon -> Settings to enable it."
            return
        }

        // Show spinner during the capture attempt so failures aren't "silent".
        self.isProcessing = true
        defer {
            if self.processNonce == nonce {
                self.isProcessing = false
            }
        }
        
        // 2. Use pre-captured target or try to capture now
        let targetToUse: CaptureTarget?
        if let preCapturedTarget {
            targetToUse = preCapturedTarget
        } else {
            targetToUse = await AccessibilityManager.shared.captureSelectedText(preferredApp: preferredApp)
        }

        guard processNonce == nonce else { return }
        
        guard let target = targetToUse else {
            let appName = preferredApp?.localizedName
            if correctedText.isEmpty {
                if let appName, !appName.isEmpty {
                    self.errorMessage = "Could not capture selected text from \(appName). Try selecting text again. If it still fails, press Cmd+C in \(appName) first, then trigger McWritely."
                } else {
                    self.errorMessage = "No text selected. Please select some text in another app."
                }
            }
            return
        }
        
        guard let service = aiService else {
            self.errorMessage = "Please set your OpenAI API Key in Settings."
            return
        }
        
        self.currentTarget = target
        self.originalText = target.selectedText
        self.correctedText = ""
        self.errorMessage = nil
        
        do {
            let result = try await service.correctText(target.selectedText)
            guard processNonce == nonce else { return }
            self.correctedText = result
        } catch {
            guard processNonce == nonce else { return }
            self.errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func applyCorrection() async {
        guard let target = currentTarget else { return }
        self.errorMessage = nil
        let result = await AccessibilityManager.shared.replaceText(in: target, with: correctedText)
        if result.shouldClosePanel {
            // Success! Reset and hide.
            PanelManager.shared.hide()
            self.originalText = ""
            self.correctedText = ""
            self.currentTarget = nil
            self.errorMessage = nil
            return
        }

        self.errorMessage = result.detail ?? "Could not verify replacement. The corrected text is on your clipboard."
    }

    @MainActor
    func showCaptureFailure(preferredApp: NSRunningApplication?) {
        let appName = preferredApp?.localizedName
        reset()
        if let appName, !appName.isEmpty {
            errorMessage = "Could not capture selected text from \(appName). Try selecting text again. If it still fails, press Cmd+C in \(appName) first, then trigger McWritely."
        } else {
            errorMessage = "No text selected. Please select some text in another app."
        }
    }

    func reset() {
        processNonce = UUID()
        originalText = ""
        correctedText = ""
        isProcessing = false
        errorMessage = nil
        currentTarget = nil
    }
    
    private func updateService(for apiKey: String) {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            aiService = nil
        } else {
            aiService = OpenAIService(apiKey: trimmed)
        }
    }
}
