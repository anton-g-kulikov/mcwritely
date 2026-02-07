import Foundation

class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var apiKey: String {
        didSet {
            let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                KeychainStore.shared.delete(service: Self.keychainService, account: Self.keychainAccount)
            } else {
                KeychainStore.shared.save(trimmed, service: Self.keychainService, account: Self.keychainAccount)
            }
        }
    }
    
    private init() {
        SettingsMigration.migrate(userDefaults: .standard)

        if let storedKey = KeychainStore.shared.read(service: Self.keychainService, account: Self.keychainAccount) {
            self.apiKey = storedKey
        } else if let legacyKey = UserDefaults.standard.string(forKey: "openai_api_key"), !legacyKey.isEmpty {
            self.apiKey = legacyKey
            _ = KeychainStore.shared.save(legacyKey, service: Self.keychainService, account: Self.keychainAccount)
            UserDefaults.standard.removeObject(forKey: "openai_api_key")
        } else {
            self.apiKey = ""
        }
    }
    
    var hasValidKey: Bool {
        return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private static var keychainService: String {
        return Bundle.main.bundleIdentifier ?? "com.antonkulikov.mcwritely"
    }
    private static let keychainAccount = "openai_api_key"
}
