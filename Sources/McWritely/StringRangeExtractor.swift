import Foundation

enum StringRangeExtractor {
    static func substring(in string: String, range: NSRange) -> String? {
        if range.location < 0 || range.length <= 0 { return nil }
        guard let r = Range(range, in: string) else { return nil }
        let s = String(string[r])
        return s.isEmpty ? nil : s
    }
}

