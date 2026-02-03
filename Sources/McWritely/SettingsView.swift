import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    
    var body: some View {
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
                    Toggle("Keep new text in the clipboard", isOn: $settings.keepNewTextInClipboard)
                    
                    Text("When enabled, McWritely leaves the corrected text on your clipboard after Apply.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            SettingsSection(title: "Permissions") {
                VStack(alignment: .leading, spacing: 10) {
                    PermissionRow(
                        title: "Accessibility Access",
                        isGranted: AccessibilityManager.shared.checkPermissions(),
                        onRequest: { _ = AccessibilityManager.shared.checkPermissions(prompt: true) }
                    )
                    
                    PermissionRow(
                        title: "Input Monitoring",
                        isGranted: AccessibilityManager.shared.checkInputMonitoringPermissions(),
                        onRequest: { _ = AccessibilityManager.shared.checkInputMonitoringPermissions(prompt: true) }
                    )
                    
                    Text("Input Monitoring is required for the global hotkey to work.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(Color.white)
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
