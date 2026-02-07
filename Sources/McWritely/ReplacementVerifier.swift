import Foundation

enum ReplacementVerifier {
    static func isVerified(selectedText: String?, value: String?, correctedText: String) -> Bool {
        let corrected = correctedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if corrected.isEmpty { return false }

        if let selectedText {
            let selected = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !selected.isEmpty, selected == corrected {
                return true
            }
        }

        if let value, !value.isEmpty, value.contains(corrected) {
            return true
        }

        return false
    }
}

