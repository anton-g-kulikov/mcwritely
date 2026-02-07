import Foundation

enum SelectionTextResolver {
    static func resolve(
        selectedText: String?,
        stringForRange: String?,
        value: String?,
        selectedRange: NSRange?
    ) -> String? {
        if let s = selectedText?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return s
        }

        if let s = stringForRange?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return s
        }

        if let value, let selectedRange,
           let extracted = StringRangeExtractor.substring(in: value, range: selectedRange) {
            let trimmed = extracted.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }
}

