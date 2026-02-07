import Foundation

struct ReplacementResult {
    enum Method {
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

    var shouldClosePanel: Bool { state == .verified }
}

