import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI Configuration")) {
                SecureField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Your key is stored locally in macOS Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section(header: Text("Permissions")) {
                HStack {
                    Text("Accessibility Access")
                    Spacer()
                    if AccessibilityManager.shared.checkPermissions() {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Request Access") {
                            _ = AccessibilityManager.shared.checkPermissions(prompt: true)
                        }
                    }
                }
                
                HStack {
                    Text("Input Monitoring")
                    Spacer()
                    if AccessibilityManager.shared.checkInputMonitoringPermissions() {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Request Access") {
                            _ = AccessibilityManager.shared.checkInputMonitoringPermissions(prompt: true)
                        }
                    }
                }
                
                Text("Input Monitoring is required for the global hotkey to work.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}
