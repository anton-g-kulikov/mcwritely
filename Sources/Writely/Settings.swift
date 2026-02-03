import Foundation

class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
        }
    }
    
    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    var hasValidKey: Bool {
        return !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
