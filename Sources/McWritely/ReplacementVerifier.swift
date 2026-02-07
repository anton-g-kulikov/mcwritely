import Foundation

enum ReplacementVerifier {
    static func isVerified(selectedText: String?, value: String?, correctedText: String) -> Bool {
        let corrected = TextNormalizer.normalizeForVerification(correctedText)
        if corrected.isEmpty { return false }

        if let selectedText {
            let selected = TextNormalizer.normalizeForVerification(selectedText)
            if !selected.isEmpty, selected == corrected {
                return true
            }
        }

        if let value, !value.isEmpty {
            let normalizedValue = TextNormalizer.normalizeForVerification(value)
            if !normalizedValue.isEmpty, normalizedValue.contains(corrected) {
                return true
            }
        }
        return false
    }
}
