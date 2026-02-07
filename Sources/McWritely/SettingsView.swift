import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var hasAccessibilityAccess: Bool = AccessibilityManager.shared.checkPermissions()
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(title: "OpenAI Configuration") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        SecureField("API Key", text: $settings.apiKey)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.12))
                            .cornerRadius(8)
                        
                        Text("Your key is stored locally in macOS Keychain.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                SettingsSection(title: "Clipboard") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("McWritely always leaves the corrected text on your clipboard after Apply.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                SettingsSection(title: "Permissions") {
                    VStack(alignment: .leading, spacing: 10) {
                        PermissionRow(
                            title: "Accessibility Access",
                            isGranted: hasAccessibilityAccess,
                            onRequest: requestAccessibilityAccess
                        )
                        

                    }
                }
            }
            .padding(20)
            
            Spacer()
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
        }
        .frame(width: 420)
        .background(Color.white)
        .onAppear { refreshPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Returning from System Settings should refresh the trust state.
            refreshPermissions()
        }
    }

    private func refreshPermissions() {
        hasAccessibilityAccess = AccessibilityManager.shared.checkPermissions()
    }

    private func requestAccessibilityAccess() {
        // Best-effort: macOS may not show a prompt, but this doesn't hurt.
        _ = AccessibilityManager.shared.checkPermissions(prompt: true)

        // Always open the correct System Settings pane.
        AccessibilityManager.shared.openAccessibilitySettings()

        // Refresh a few times because trust updates can be delayed.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { refreshPermissions() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { refreshPermissions() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { refreshPermissions() }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content
        }
        .padding(14)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
}

private struct PermissionRow: View {
    let title: String
    let isGranted: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Request Access", action: onRequest)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}
