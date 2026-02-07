import Foundation
import AppKit

final class AppFocusTracker {
    static let shared = AppFocusTracker()

    private var observer: Any?
    private var lastNonMcWritelyPID: pid_t?

    private init() {}

    func start() {
        if observer != nil { return }
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            if app.bundleIdentifier != Bundle.main.bundleIdentifier {
                self.lastNonMcWritelyPID = app.processIdentifier
            }
        }
    }

    func lastNonMcWritelyApp() -> NSRunningApplication? {
        guard let pid = lastNonMcWritelyPID else { return nil }
        return NSRunningApplication(processIdentifier: pid)
    }
}

