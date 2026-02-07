import Foundation
import AppKit

enum PasteboardTextExtractor {
    static func plainText(fromRTF data: Data) -> String? {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.rtf
        ]
        let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
        return attributed?.string.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    static func plainText(fromHTML data: Data) -> String? {
        // Keep this deterministic and testable: do a best-effort HTML->text conversion.
        // (AppKit HTML parsing is not always available in non-AppKit test contexts.)
        if let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) {
            return plainText(fromHTMLString: html)
        }

        // Last-ditch fallback to AppKit parsing (may still return nil).
        var docAttributes: NSDictionary?
        if let attributed = NSAttributedString(html: data, documentAttributes: &docAttributes) {
            return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
        return nil
    }

    private static func plainText(fromHTMLString html: String) -> String? {
        var s = html

        // Remove script/style blocks.
        s = s.replacingOccurrences(
            of: "(?is)<(script|style)\\b[^>]*>.*?</\\1>",
            with: "",
            options: [.regularExpression]
        )

        // Preserve basic line breaks.
        s = s.replacingOccurrences(of: "(?i)<br\\s*/?>", with: "\n", options: [.regularExpression])
        s = s.replacingOccurrences(of: "(?i)</p\\s*>", with: "\n", options: [.regularExpression])
        s = s.replacingOccurrences(of: "(?i)</div\\s*>", with: "\n", options: [.regularExpression])

        // Strip remaining tags.
        s = s.replacingOccurrences(of: "(?s)<[^>]+>", with: "", options: [.regularExpression])

        // Decode a small set of entities plus numeric entities.
        s = decodeHTMLEntities(s)

        // Normalize whitespace.
        s = s.replacingOccurrences(of: "\u{00A0}", with: " ")
        s = s.replacingOccurrences(of: "[ \\t\\r\\f\\v]+", with: " ", options: [.regularExpression])
        s = s.replacingOccurrences(of: "\\n\\s*\\n+", with: "\n", options: [.regularExpression])

        return s.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    static func plainText(fromReadObjects objects: [Any]?) -> String? {
        guard let objects else { return nil }
        for obj in objects {
            if let s = obj as? String {
                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            } else if let s = obj as? NSString {
                let trimmed = String(s).trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            } else if let a = obj as? NSAttributedString {
                let trimmed = a.string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return nil
    }

    static func plainText(from pasteboard: NSPasteboard) -> String? {
        if let s = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !s.isEmpty {
            return s
        }

        // Let AppKit coerce whatever the app wrote into a plain string when possible.
        if let s = plainText(fromReadObjects: pasteboard.readObjects(forClasses: [NSString.self], options: nil)) {
            return s
        }

        if let data = pasteboard.data(forType: .rtf),
           let s = plainText(fromRTF: data) {
            return s
        }

        if let data = pasteboard.data(forType: .html),
           let s = plainText(fromHTML: data) {
            return s
        }

        return nil
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

private func decodeHTMLEntities(_ input: String) -> String {
    // Minimal entity decoding for clipboard HTML. Keep this small and predictable.
    var s = input
    s = s.replacingOccurrences(of: "&nbsp;", with: " ")
    s = s.replacingOccurrences(of: "&amp;", with: "&")
    s = s.replacingOccurrences(of: "&lt;", with: "<")
    s = s.replacingOccurrences(of: "&gt;", with: ">")
    s = s.replacingOccurrences(of: "&quot;", with: "\"")
    s = s.replacingOccurrences(of: "&#39;", with: "'")

    // Decode numeric entities: &#123; and &#x1F600;
    let pattern = "&#(x?[0-9A-Fa-f]+);"
    guard let re = try? NSRegularExpression(pattern: pattern) else { return s }
    let ns = s as NSString
    let matches = re.matches(in: s, range: NSRange(location: 0, length: ns.length))
    if matches.isEmpty { return s }

    var out = s
    for m in matches.reversed() {
        guard m.numberOfRanges >= 2 else { continue }
        let codeStr = ns.substring(with: m.range(at: 1))
        let scalarValue: UInt32?
        if codeStr.lowercased().hasPrefix("x") {
            scalarValue = UInt32(codeStr.dropFirst(), radix: 16)
        } else {
            scalarValue = UInt32(codeStr, radix: 10)
        }
        guard let v = scalarValue, let scalar = UnicodeScalar(v) else { continue }
        out = (out as NSString).replacingCharacters(in: m.range(at: 0), with: String(scalar))
    }
    return out
}
