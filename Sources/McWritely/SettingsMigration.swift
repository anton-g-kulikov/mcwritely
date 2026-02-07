import Foundation

enum SettingsMigration {
    static func migrate(userDefaults: UserDefaults = .standard) {
        // Legacy key: clipboard restore behavior no longer exists (clipboard always keeps corrected text after Apply).
        if userDefaults.object(forKey: "keep_new_text_in_clipboard") != nil {
            userDefaults.removeObject(forKey: "keep_new_text_in_clipboard")
        }
    }
}

