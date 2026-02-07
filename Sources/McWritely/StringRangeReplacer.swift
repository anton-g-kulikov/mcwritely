import Foundation

enum StringRangeReplacer {
    static func replacing(in string: String, range: NSRange, with replacement: String) -> String? {
        if range.location < 0 || range.length < 0 { return nil }
        guard let r = Range(range, in: string) else { return nil }
        var out = string
        out.replaceSubrange(r, with: replacement)
        return out
    }
}

