import Foundation
import SwiftUI

class CorrectionViewModel: ObservableObject {
    @Published var originalText: String = ""
    @Published var correctedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var currentTarget: CaptureTarget? = nil
    
    private let aiService: OpenAIService?
    
    init() {
        if Settings.shared.hasValidKey {
            self.aiService = OpenAIService(apiKey: Settings.shared.apiKey)
        } else {
            self.aiService = nil
        }
    }
    
    @MainActor
    func processSelection(preCapturedTarget: CaptureTarget? = nil) async {
        self.errorMessage = nil
        
        // 1. Check Permissions first
        if !AccessibilityManager.shared.checkPermissions() {
            self.errorMessage = "Accessibility Permission Required. Please click the icon -> Settings to enable it."
            return
        }
        
        // 2. Use pre-captured target or try to capture now
        let targetToUse: CaptureTarget? = preCapturedTarget ?? AccessibilityManager.shared.captureSelectedText()
        
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
    
    func applyCorrection() {
        guard let target = currentTarget else { return }
        let success = AccessibilityManager.shared.replaceText(in: target.element, with: correctedText)
        if !success {
            self.errorMessage = "Failed to replace text. Ensure the app is still focused."
        } else {
            // Success! Reset or close popover.
            self.originalText = ""
            self.correctedText = ""
            self.currentTarget = nil
        }
    }
}
