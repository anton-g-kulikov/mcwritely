import AppKit
import CoreGraphics

struct CorrectionPanelState {
    let correctedText: String
    let originalText: String
    let isProcessing: Bool
    let errorMessage: String?

    var showsApplySuggestion: Bool {
        !correctedText.isEmpty
    }

    var hasVisibleText: Bool {
        !originalText.isEmpty || !correctedText.isEmpty
    }

    var bodyText: String {
        if !correctedText.isEmpty {
            return correctedText
        }

        if isProcessing {
            return originalText
        }

        return ""
    }
}

enum CorrectionPanelLayout {
    static let contentWidth: CGFloat = 420
    static let outerPadding: CGFloat = 20

    private static let contentPadding: CGFloat = 24
    private static let textInset: CGFloat = 16
    private static let idleBodyHeight: CGFloat = 112
    private static let loadingMinHeight: CGFloat = 72
    private static let loadingMaxHeight: CGFloat = 104
    private static let resultMinHeight: CGFloat = 88
    private static let resultMaxHeight: CGFloat = 160
    private static let minContentHeight: CGFloat = 232
    private static let maxContentHeight: CGFloat = 380
    private static let closeOnlyFooterHeight: CGFloat = 52
    private static let applyFooterHeight: CGFloat = 92
    private static let bodyVerticalReserve: CGFloat = 92
    private static let bodyFont: NSFont = .systemFont(ofSize: 17, weight: .regular)

    static var windowSize: CGSize {
        windowSize(for: CorrectionPanelState(correctedText: "", originalText: "", isProcessing: false, errorMessage: nil))
    }

    static func windowSize(for state: CorrectionPanelState) -> CGSize {
        let contentHeight = contentHeight(for: state)
        return CGSize(
            width: contentWidth + (outerPadding * 2),
            height: contentHeight + (outerPadding * 2)
        )
    }

    static func contentHeight(for state: CorrectionPanelState) -> CGFloat {
        let footerHeight = state.showsApplySuggestion ? applyFooterHeight : closeOnlyFooterHeight
        let errorHeight = errorHeight(for: state.errorMessage)
        let bodyHeight = bodyHeight(for: state)
        let total = bodyVerticalReserve + errorHeight + bodyHeight + footerHeight
        return clamp(total, lower: minContentHeight, upper: maxContentHeight)
    }

    static func bodyHeight(for state: CorrectionPanelState) -> CGFloat {
        if state.showsApplySuggestion {
            return resultAreaHeight(for: state.correctedText)
        }

        if state.isProcessing && !state.originalText.isEmpty {
            return loadingPreviewHeight(for: state.originalText)
        }

        if state.hasVisibleText {
            return loadingMinHeight
        }

        return idleBodyHeight
    }

    static func resultAreaHeight(for text: String) -> CGFloat {
        let measured = measuredTextHeight(for: text, width: textBodyWidth)
        return clamp(measured + textInset, lower: resultMinHeight, upper: resultMaxHeight)
    }

    static func loadingPreviewHeight(for text: String) -> CGFloat {
        let measured = measuredTextHeight(for: text, width: textBodyWidth)
        return clamp(measured, lower: loadingMinHeight, upper: loadingMaxHeight)
    }

    private static var textBodyWidth: CGFloat {
        contentWidth - (contentPadding * 2) - textInset
    }

    private static func errorHeight(for message: String?) -> CGFloat {
        guard let message, !message.isEmpty else { return 0 }
        let measured = measuredTextHeight(for: message, width: textBodyWidth)
        return measured + 30
    }

    private static func measuredTextHeight(for text: String, width: CGFloat) -> CGFloat {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }

        let rect = NSString(string: text).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: bodyFont]
        )
        return ceil(rect.height)
    }

    private static func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }
}
