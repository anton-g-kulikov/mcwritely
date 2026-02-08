import Foundation

struct ClipboardReassertPolicy {
    static func shouldReassert(
        currentClipboardText: String,
        correctedText: String,
        originalSelectedText: String
    ) -> Bool {
        if currentClipboardText == correctedText { return false }
        if currentClipboardText.hasPrefix("MCWR_") { return true }

        // Electron/webviews can normalize the clipboard contents (NBSP, whitespace runs, newlines).
        // If we see something that normalizes to the original selection, it's likely from our own
        // copy-based selection checks and we should reassert the corrected text.
        if TextNormalizer.normalizeForVerification(currentClipboardText) ==
            TextNormalizer.normalizeForVerification(originalSelectedText) {
            return true
        }

        return false
    }
}

