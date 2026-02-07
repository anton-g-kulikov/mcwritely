import Foundation

// Pure logic (unit-testable): choose the most likely "Copy" menu item when multiple items use cmdChar "c".
// This primarily targets Electron apps where invoking Edit -> Copy via AX is more reliable than key injection.

struct MenuCopyCandidate: Equatable {
    var title: String?
    var cmdChar: String?
    var cmdModifiers: Int?
    var enabled: Bool?

    init(title: String?, cmdChar: String?, cmdModifiers: Int?, enabled: Bool?) {
        self.title = title
        self.cmdChar = cmdChar
        self.cmdModifiers = cmdModifiers
        self.enabled = enabled
    }
}

enum MenuCopyCandidateSelector {
    // Carbon modifier constants (as used by kAXMenuItemCmdModifiersAttribute).
    // We define them locally to keep this file lightweight and not require Carbon in tests.
    private static let cmdKey: Int = 256
    private static let shiftKey: Int = 512
    private static let optionKey: Int = 2048
    private static let controlKey: Int = 4096

    static func chooseBest(from candidates: [(candidate: MenuCopyCandidate, index: Int)]) -> (MenuCopyCandidate, Int)? {
        var best: (MenuCopyCandidate, Int, Int)? = nil // (candidate, index, score)

        for (c, idx) in candidates {
            let score = score(candidate: c)
            guard score > Int.min / 2 else { continue }
            if let currentBest = best {
                if score > currentBest.2 {
                    best = (c, idx, score)
                }
            } else {
                best = (c, idx, score)
            }
        }

        guard let best else { return nil }
        return (best.0, best.1)
    }

    static func score(candidate: MenuCopyCandidate) -> Int {
        if candidate.enabled == false { return Int.min }

        guard
            let ch = candidate.cmdChar?.trimmingCharacters(in: .whitespacesAndNewlines),
            ch.count == 1,
            ch.lowercased() == "c"
        else {
            return Int.min
        }

        var score = 100

        let mods = candidate.cmdModifiers ?? cmdKey
        if mods == cmdKey {
            score += 1000
        }

        // Penalize extra modifiers heavily; "Copy Style" etc often uses Cmd+Opt+C.
        if (mods & optionKey) != 0 { score -= 300 }
        if (mods & shiftKey) != 0 { score -= 200 }
        if (mods & controlKey) != 0 { score -= 200 }

        if let title = candidate.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            let t = title.lowercased()
            if t == "copy" { score += 80 }
            else if t.hasPrefix("copy") { score += 30 }
            else if t.contains("copy") { score += 10 }
        }

        return score
    }
}

