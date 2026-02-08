import Foundation

struct ReplacementResult {
    enum Method {
        case axValueRange
        case axSelectedText
        case paste
    }

    enum State {
        case verified
        case unverified
        case failed
    }

    let method: Method?
    let state: State
    let detail: String?

    // We treat "unverified" as "applied but not provably verified" and close the panel.
    // The corrected text remains on the clipboard so the user can manually paste if needed.
    var shouldClosePanel: Bool { state != .failed }
}
