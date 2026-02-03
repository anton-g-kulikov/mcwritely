import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI Configuration")) {
                SecureField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Your key is stored locally in macOS Keychain/UserDefaults.")
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
            }
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}
