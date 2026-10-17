/*
 * Live Translate ViewModel
 * 实时翻译状态管理
 */

import Foundation
import SwiftUI
import UIKit

@MainActor
class LiveTranslateViewModel: ObservableObject {

    // MARK: - Connection State
    @Published var isConnected = false
    @Published var isRecording = false

    // MARK: - Translation State
    @Published var currentTranslation = ""       // 当前翻译结果
    @Published var currentOriginal = ""
    @Published var streamingTranslation = ""     // 流式翻译片段
    @Published var translationHistory: [TranslateRecord] = []

    // MARK: - Error State
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Settings (持久化)
    @Published var targetLanguage: TranslateLanguage {
        didSet {
            UserDefaults.standard.set(targetLanguage.rawValue, forKey: "translate_target_language")
            updateServiceSettings()
        }
    }

    @Published var audioOutputEnabled: Bool {
        didSet {
            UserDefaults.standard.set(audioOutputEnabled, forKey: "translate_audio_enabled")
            updateServiceSettings()
        }
    }

    /// 使用 iPhone 麦克风（而非眼镜麦克风）
    /// 眼镜麦克风适合翻译自己说的话，iPhone 麦克风适合翻译对方说的话
    @Published var usePhoneMic: Bool {
        didSet {
            UserDefaults.standard.set(usePhoneMic, forKey: "translate_use_phone_mic")
        }
    }

    // MARK: - Private
    private var translateService: LiveTranslateService?

    // MARK: - Init

    init() {
        // 从 UserDefaults 加载设置
        let savedTarget = UserDefaults.standard.string(forKey: "translate_target_language") ?? "zh"
        self.targetLanguage = TranslateLanguage(rawValue: savedTarget) ?? .zh

        self.audioOutputEnabled = UserDefaults.standard.object(forKey: "translate_audio_enabled") as? Bool ?? true
        self.usePhoneMic = UserDefaults.standard.object(forKey: "translate_use_phone_mic") as? Bool ?? false
    }

    // MARK: - Connection

    func connect() {
        let apiKey = APIKeyManager.shared.getOpenAIAPIKey() ?? ""
        guard !apiKey.isEmpty else {
            errorMessage = "livetranslate.error.noApiKey".localized
            showError = true
            return
        }

        translateService = LiveTranslateService(apiKey: apiKey)
        setupCallbacks()

        translateService?.updateSettings(
            targetLanguage: targetLanguage,
            audioEnabled: audioOutputEnabled
        )

        translateService?.connect()
    }

    func disconnect() {
        translateService?.disconnect()
        translateService = nil
        isConnected = false
        isRecording = false
    }

    // MARK: - Recording

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        translateService?.startRecording(usePhoneMic: usePhoneMic)
        isRecording = true

    }

    func stopRecording() {
        translateService?.stopRecording()
        isRecording = false

        // 保存当前翻译到历史
        if !currentTranslation.isEmpty {
            let record = TranslateRecord(
                targetLanguage: targetLanguage,
                originalText: currentOriginal,
                translatedText: currentTranslation
            )
            translationHistory.insert(record, at: 0)

            // 限制历史记录数量
            if translationHistory.count > 50 {
                translationHistory = Array(translationHistory.prefix(50))
            }
        }
    }

    // MARK: - Private Methods

    private func setupCallbacks() {
        translateService?.onConnected = { [weak self] in
            DispatchQueue.main.async {
                self?.isConnected = true
                print("✅ [TranslateVM] 已连接")
            }
        }

        translateService?.onTranslationDelta = { [weak self] delta in
            DispatchQueue.main.async {
                self?.currentTranslation += delta
            }
        }

        translateService?.onOriginalDelta = { [weak self] delta in
            DispatchQueue.main.async {
                self?.currentOriginal += delta
            }
        }

        translateService?.onTranslationText = { [weak self] text in
            DispatchQueue.main.async {
                self?.currentTranslation = text
                self?.streamingTranslation = ""
            }
        }

        translateService?.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error
                self?.showError = true
            }
        }
    }

    private func updateServiceSettings() {
        translateService?.updateSettings(
            targetLanguage: targetLanguage,
            audioEnabled: audioOutputEnabled
        )
    }

    // MARK: - Clear

    func clearTranslation() {
        currentTranslation = ""
        streamingTranslation = ""
        currentOriginal = ""
    }

    func clearHistory() {
        translationHistory.removeAll()
    }
}
