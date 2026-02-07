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
        self.errorMessage = nil
        
        // 1. Check Permissions first
        if !AccessibilityManager.shared.checkPermissions() {
            self.errorMessage = "Accessibility Permission Required. Please click the icon -> Settings to enable it."
            return
        }
        
        // 2. Use pre-captured target or try to capture now
        let targetToUse: CaptureTarget?
        if let preCapturedTarget {
            targetToUse = preCapturedTarget
        } else {
            targetToUse = await AccessibilityManager.shared.captureSelectedText(preferredApp: preferredApp)
        }
        
        guard let target = targetToUse else {
            if correctedText.isEmpty {
                self.errorMessage = "No text selected. Please select some text in another app."
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
        self.isProcessing = true
        self.errorMessage = nil
        
        do {
            let result = try await service.correctText(target.selectedText)
            self.correctedText = result
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        self.isProcessing = false
    }
    
    @MainActor
    func applyCorrection() async {
        guard let target = currentTarget else { return }
        let success = await AccessibilityManager.shared.replaceText(in: target, with: correctedText)
        if !success {
            self.errorMessage = "Failed to replace text. Ensure the app is still focused."
        } else {
            // Success! Reset and hide.
            PanelManager.shared.hide()
            self.originalText = ""
            self.correctedText = ""
            self.currentTarget = nil
        }
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
