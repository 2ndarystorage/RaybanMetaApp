/*
 * Language Manager
 * App language selection
 */

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case chinese = "zh-Hans"
    case japanese = "ja"
    case english = "en"

    var displayName: String {
        switch self {
        case .system: return "システム設定に従う"
        case .chinese: return "中国語"
        case .japanese: return "日本語"
        case .english: return "English"
        }
    }

    var locale: Locale {
        switch self {
        case .system: return Locale.current
        case .chinese: return Locale(identifier: "zh-Hans")
        case .japanese: return Locale(identifier: "ja")
        case .english: return Locale(identifier: "en")
        }
    }
}

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private let languageKey = "app_language"

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
            updateBundle()
        }
    }

    // Use nonisolated(unsafe) to allow access from any thread
    // This is safe because we only read after initialization
    nonisolated(unsafe) static var currentBundle: Bundle = .main

    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: languageKey) ?? "system"
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .system
        updateBundle()
    }

    private func updateBundle() {
        let languageCode: String

        switch currentLanguage {
        case .system:
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            if preferredLanguage.hasPrefix("zh") {
                languageCode = "zh-Hans"
            } else if preferredLanguage.hasPrefix("ja") {
                languageCode = "ja"
            } else {
                languageCode = "en"
            }
        case .chinese:
            languageCode = "zh-Hans"
        case .japanese:
            languageCode = "ja"
        case .english:
            languageCode = "en"
        }

        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            LanguageManager.currentBundle = bundle
        } else {
            LanguageManager.currentBundle = .main
        }
    }

    /// Get localized string
    func localizedString(_ key: String) -> String {
        return Self.lookup(key)
    }

    /// Get localized string with format arguments
    func localizedString(_ key: String, _ args: CVarArg...) -> String {
        let format = Self.lookup(key)
        return String(format: format, arguments: args)
    }

    nonisolated static func lookup(_ key: String) -> String {
        let value = currentBundle.localizedString(forKey: key, value: nil, table: nil)
        guard value == key,
              let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let fallback = Bundle(path: path) else { return value }
        return fallback.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Check if current language is Chinese
    var isChinese: Bool {
        switch currentLanguage {
        case .chinese:
            return true
        case .english, .japanese:
            return false
        case .system:
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            return preferredLanguage.hasPrefix("zh")
        }
    }

    /// Get language code for API calls (TTS, etc.)
    var apiLanguageCode: String {
        return Self.staticApiLanguageCode
    }

    /// Get TTS voice based on current language
    var ttsVoice: String {
        return apiLanguageCode == "English" ? "Ethan" : "Cherry"
    }

    // Static helpers for nonisolated access
    nonisolated static var staticIsChinese: Bool {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        let language = AppLanguage(rawValue: savedLanguage) ?? .system
        switch language {
        case .chinese:
            return true
        case .english, .japanese:
            return false
        case .system:
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            return preferredLanguage.hasPrefix("zh")
        }
    }

    nonisolated static var staticApiLanguageCode: String {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        if savedLanguage == "ja" || (savedLanguage == "system" && Locale.preferredLanguages.first?.hasPrefix("ja") == true) {
            return "Japanese"
        }
        return staticIsChinese ? "Chinese" : "English"
    }

    nonisolated static var staticTtsVoice: String {
        return staticApiLanguageCode == "English" ? "Ethan" : "Cherry"
    }
}

// MARK: - String Extension for Localization

extension String {
    /// Localized string - can be called from any thread
    var localized: String {
        return LanguageManager.lookup(self)
    }

    /// Localized string with format arguments - can be called from any thread
    func localized(_ args: CVarArg...) -> String {
        let format = LanguageManager.lookup(self)
        return String(format: format, arguments: args)
    }
}
