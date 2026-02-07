import Foundation
import AppKit

extension Notification.Name {
    static let triggerCorrection = Notification.Name("TriggerCorrection")
    static let resetCorrectionUI = Notification.Name("ResetCorrectionUI")
}

struct TriggerCorrectionContext {
    let preferredApp: NSRunningApplication?
    let capturedTarget: CaptureTarget?
}
