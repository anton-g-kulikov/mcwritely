import Foundation

enum TextNormalizer {
    static func normalizeForVerification(_ input: String) -> String {
        var s = input

        // Normalize newlines to LF.
        s = s.replacingOccurrences(of: "\r\n", with: "\n")
        s = s.replacingOccurrences(of: "\r", with: "\n")

        // Normalize NBSP to regular spaces.
        s = s.replacingOccurrences(of: "\u{00A0}", with: " ")

        // Collapse whitespace runs (space/tabs/newlines) to a single space.
        // This is intentionally lossy: it is used only for verification heuristics.
        if let re = try? NSRegularExpression(pattern: "\\s+", options: []) {
            let range = NSRange(location: 0, length: (s as NSString).length)
            s = re.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: " ")
        }

        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

