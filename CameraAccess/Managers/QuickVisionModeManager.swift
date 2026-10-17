/*
 * Quick Vision Mode Manager
 * 快速识图模式管理器 - 管理当前模式、自定义提示词、翻译目标语言
 */

import Foundation
import SwiftUI

class QuickVisionModeManager: ObservableObject {
    static let shared = QuickVisionModeManager()

    private let userDefaults = UserDefaults.standard
    private let modeKey = "quickVisionMode"
    private let customPromptKey = "quickVisionCustomPrompt"
    private let translateTargetLanguageKey = "quickVisionTranslateTargetLanguage"

    @Published var currentMode: QuickVisionMode {
        didSet {
            userDefaults.set(currentMode.rawValue, forKey: modeKey)
            print("📋 [QuickVisionModeManager] 模式已切换: \(currentMode.displayName)")
        }
    }

    @Published var customPrompt: String {
        didSet {
            userDefaults.set(customPrompt, forKey: customPromptKey)
        }
    }

    @Published var translateTargetLanguage: String {
        didSet {
            userDefaults.set(translateTargetLanguage, forKey: translateTargetLanguageKey)
        }
    }

    // 支持的翻译目标语言
    static let supportedLanguages: [(code: String, name: String)] = [
        ("zh-CN", "中国語"),
        ("en-US", "English"),
        ("ja-JP", "日本語"),
        ("ko-KR", "한국어"),
        ("fr-FR", "Français"),
        ("de-DE", "Deutsch"),
        ("es-ES", "Español"),
        ("it-IT", "Italiano"),
        ("pt-BR", "Português"),
        ("ru-RU", "Русский")
    ]

    private init() {
        // 加载保存的模式
        if let savedMode = userDefaults.string(forKey: modeKey),
           let mode = QuickVisionMode(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .standard
        }

        // 加载自定义提示词
        self.customPrompt = userDefaults.string(forKey: customPromptKey) ?? "quickvision.custom.default".localized

        // 加载翻译目标语言（默认跟随系统语言）
        if let savedLanguage = userDefaults.string(forKey: translateTargetLanguageKey) {
            self.translateTargetLanguage = savedLanguage
        } else {
            switch LanguageManager.staticApiLanguageCode {
            case "Chinese": self.translateTargetLanguage = "zh-CN"
            case "Japanese": self.translateTargetLanguage = "ja-JP"
            default: self.translateTargetLanguage = "en-US"
            }
        }
    }

    // MARK: - Get Current Prompt

    /// 获取当前模式的完整提示词
    func getPrompt() -> String {
        switch currentMode {
        case .custom:
            return customPrompt
        case .translate:
            return getTranslatePrompt()
        default:
            return currentMode.prompt
        }
    }

    /// 获取指定模式的提示词
    func getPrompt(for mode: QuickVisionMode) -> String {
        switch mode {
        case .custom:
            return customPrompt
        case .translate:
            return getTranslatePrompt()
        default:
            return mode.prompt
        }
    }

    /// 获取翻译模式的提示词（包含目标语言）
    private func getTranslatePrompt() -> String {
        let targetLanguageName = Self.supportedLanguages.first { $0.code == translateTargetLanguage }?.name ?? "日本語"
        let basePrompt = "prompt.quickvision.translate".localized
        return basePrompt.replacingOccurrences(of: "{LANGUAGE}", with: targetLanguageName)
    }

    // MARK: - Mode Management

    func setMode(_ mode: QuickVisionMode) {
        currentMode = mode
    }

    func setCustomPrompt(_ prompt: String) {
        customPrompt = prompt
    }

    func setTranslateTargetLanguage(_ languageCode: String) {
        translateTargetLanguage = languageCode
    }

    // MARK: - Static Access (for non-SwiftUI contexts)

    static var staticCurrentMode: QuickVisionMode {
        return shared.currentMode
    }

    static var staticPrompt: String {
        return shared.getPrompt()
    }
}
