/*
 * Quick Vision Intent
 * App Intent - 支持 Siri 和快捷指令触发快速识图
 *
 * 支持的模式：
 * - 默认模式：通用图像描述
 * - 健康识图：分析食品健康程度
 * - 盲人模式：为视障用户描述环境
 * - 阅读模式：识别并朗读文字
 * - 翻译模式：识别并翻译文字
 * - 百科模式：百科知识介绍
 * - 自定义：使用自定义提示词
 */

import AppIntents
import UIKit
import SwiftUI

// MARK: - Quick Vision Intent (Default Mode)

@available(iOS 16.0, *)
struct QuickVisionIntent: AppIntent {
    static var title: LocalizedStringResource = "クイック画像認識"
    static var description = IntentDescription("Ray-Ban Metaで撮影して画像を認識します")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "カスタム指示")
    var customPrompt: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.standard, customPrompt: customPrompt)
        return formatResult(manager)
    }
}

// MARK: - Health Mode Intent

@available(iOS 16.0, *)
struct QuickVisionHealthIntent: AppIntent {
    static var title: LocalizedStringResource = "食品の健康分析"
    static var description = IntentDescription("食品や飲み物の健康面を分析します")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.health)
        return formatResult(manager)
    }
}

// MARK: - Blind Mode Intent

@available(iOS 16.0, *)
struct QuickVisionBlindIntent: AppIntent {
    static var title: LocalizedStringResource = "周囲の説明"
    static var description = IntentDescription("目の前の環境を詳しく説明します")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.blind)
        return formatResult(manager)
    }
}

// MARK: - Reading Mode Intent

@available(iOS 16.0, *)
struct QuickVisionReadingIntent: AppIntent {
    static var title: LocalizedStringResource = "文字の読み上げ"
    static var description = IntentDescription("画像内の文字を認識して読み上げます")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.reading)
        return formatResult(manager)
    }
}

// MARK: - Translation Mode Intent

@available(iOS 16.0, *)
struct QuickVisionTranslateIntent: AppIntent {
    static var title: LocalizedStringResource = "文字の翻訳"
    static var description = IntentDescription("画像内の外国語を認識して翻訳します")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.translate)
        return formatResult(manager)
    }
}

// MARK: - Encyclopedia Mode Intent

@available(iOS 16.0, *)
struct QuickVisionEncyclopediaIntent: AppIntent {
    static var title: LocalizedStringResource = "ものを解説"
    static var description = IntentDescription("ものを認識して詳しく解説します")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.encyclopedia)
        return formatResult(manager)
    }
}

// MARK: - Helper Function

@available(iOS 16.0, *)
@MainActor
private func formatResult(_ manager: QuickVisionManager) -> some IntentResult & ProvidesDialog {
    if let result = manager.lastResult {
        return .result(dialog: "認識しました：\(result)")
    } else if let error = manager.errorMessage {
        return .result(dialog: "認識に失敗しました：\(error)")
    } else {
        return .result(dialog: "認識しました")
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, *)
struct TurboMetaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // 默认识图
        AppShortcut(
            intent: QuickVisionIntent(),
            phrases: [
                "\(.applicationName) で画像を認識",
                "\(.applicationName) でこれは何か調べて",
                "\(.applicationName) で写真を認識",
                "\(.applicationName) で撮影して調べて"
            ],
            shortTitle: "画像認識",
            systemImageName: "eye.circle.fill"
        )

        // 健康识图
        AppShortcut(
            intent: QuickVisionHealthIntent(),
            phrases: [
                "\(.applicationName) で食品を分析",
                "\(.applicationName) で健康分析",
                "\(.applicationName) でこの食べ物を調べて"
            ],
            shortTitle: "食品の健康分析",
            systemImageName: "heart.circle.fill"
        )

        // 盲人模式
        AppShortcut(
            intent: QuickVisionBlindIntent(),
            phrases: [
                "\(.applicationName) で周囲を説明",
                "\(.applicationName) で周りを見て",
                "\(.applicationName) で前方を確認"
            ],
            shortTitle: "周囲の説明",
            systemImageName: "figure.walk.circle.fill"
        )

        // 阅读模式
        AppShortcut(
            intent: QuickVisionReadingIntent(),
            phrases: [
                "\(.applicationName) で文字を読んで",
                "\(.applicationName) でこれを読み上げて",
                "\(.applicationName) で文章を読んで"
            ],
            shortTitle: "文字の読み上げ",
            systemImageName: "text.viewfinder"
        )

        // 翻译模式
        AppShortcut(
            intent: QuickVisionTranslateIntent(),
            phrases: [
                "\(.applicationName) で翻訳して",
                "\(.applicationName) でこれを訳して",
                "\(.applicationName) でこの意味を教えて"
            ],
            shortTitle: "文字の翻訳",
            systemImageName: "character.bubble.fill"
        )

        // 百科模式
        AppShortcut(
            intent: QuickVisionEncyclopediaIntent(),
            phrases: [
                "\(.applicationName) でこれを解説",
                "\(.applicationName) でものを調べて",
                "\(.applicationName) でこれは何か教えて"
            ],
            shortTitle: "ものを解説",
            systemImageName: "books.vertical.circle.fill"
        )

        // 实时对话
        AppShortcut(
            intent: LiveAIIntent(),
            phrases: [
                "\(.applicationName) でリアルタイム会話",
                "\(.applicationName) で会話を開始",
                "\(.applicationName) と話す",
                "\(.applicationName) で話し始める"
            ],
            shortTitle: "リアルタイム会話",
            systemImageName: "brain.head.profile"
        )

        // 停止实时对话
        AppShortcut(
            intent: StopLiveAIIntent(),
            phrases: [
                "\(.applicationName) の会話を停止",
                "\(.applicationName) で会話を終了",
                "\(.applicationName) の会話を終える"
            ],
            shortTitle: "会話を停止",
            systemImageName: "stop.circle.fill"
        )
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let quickVisionTriggered = Notification.Name("quickVisionTriggered")
}

// MARK: - Quick Vision Manager

@MainActor
class QuickVisionManager: ObservableObject {
    static let shared = QuickVisionManager()

    @Published var isProcessing = false
    @Published var lastResult: String?
    @Published var errorMessage: String?
    @Published var lastImage: UIImage?
    @Published var lastMode: QuickVisionMode = .standard

    // 公开 streamViewModel 用于 Intent 检查初始化状态
    private(set) var streamViewModel: StreamSessionViewModel?
    private let tts = TTSService.shared

    private init() {
        // 监听 Intent 触发
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQuickVisionTrigger(_:)),
            name: .quickVisionTriggered,
            object: nil
        )
    }

    /// 设置 StreamSessionViewModel 引用
    func setStreamViewModel(_ viewModel: StreamSessionViewModel) {
        self.streamViewModel = viewModel
    }

    @objc private func handleQuickVisionTrigger(_ notification: Notification) {
        let customPrompt = notification.userInfo?["customPrompt"] as? String
        let modeString = notification.userInfo?["mode"] as? String
        let mode = modeString.flatMap { QuickVisionMode(rawValue: $0) } ?? .standard

        Task { @MainActor in
            await performQuickVisionWithMode(mode, customPrompt: customPrompt)
        }
    }

    /// 使用指定模式执行快速识图
    func performQuickVisionWithMode(_ mode: QuickVisionMode, customPrompt: String? = nil) async {
        guard !isProcessing else {
            print("⚠️ [QuickVision] Already processing")
            return
        }

        guard let streamViewModel = streamViewModel else {
            print("❌ [QuickVision] StreamViewModel not set")
            tts.speak("画像認識を利用できません。先にアプリを開いてください")
            return
        }

        isProcessing = true
        errorMessage = nil
        lastResult = nil
        lastImage = nil
        lastMode = mode

        // 获取 API Key
        guard let apiKey = APIKeyManager.shared.getAPIKey(), !apiKey.isEmpty else {
            errorMessage = "設定でAPIキーを登録してください"
            tts.speak("設定でAPIキーを登録してください")
            isProcessing = false
            return
        }

        // 播报开始
        tts.speak("認識中です", apiKey: apiKey)

        // 获取提示词
        let prompt = customPrompt ?? QuickVisionModeManager.shared.getPrompt(for: mode)

        do {
            // 0. 检查设备是否已连接
            if !streamViewModel.hasActiveDevice {
                print("❌ [QuickVision] No active device connected")
                throw QuickVisionError.noDevice
            }

            // 1. 启动视频流（如果未启动）
            if streamViewModel.streamingStatus != .streaming {
                print("📹 [QuickVision] Starting stream...")
                await streamViewModel.handleStartStreaming()

                // 等待流进入 streaming 状态（最多 5 秒）
                var streamWait = 0
                while streamViewModel.streamingStatus != .streaming && streamWait < 50 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                    streamWait += 1
                }

                if streamViewModel.streamingStatus != .streaming {
                    print("❌ [QuickVision] Failed to start streaming")
                    throw QuickVisionError.streamNotReady
                }
            }

            // 2. 等待流稳定
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

            // 3. 清除之前的照片，然后拍照
            streamViewModel.dismissPhotoPreview()
            print("📸 [QuickVision] Capturing photo...")
            streamViewModel.capturePhoto()

            // 4. 等待照片捕获完成（最多 3 秒）
            var photoWait = 0
            while streamViewModel.capturedPhoto == nil && photoWait < 30 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                photoWait += 1
            }

            // 如果 SDK capturePhoto 失败，使用当前视频帧作为备选
            let photo: UIImage
            if let capturedPhoto = streamViewModel.capturedPhoto {
                photo = capturedPhoto
                print("📸 [QuickVision] Using SDK captured photo")
            } else if let videoFrame = streamViewModel.currentVideoFrame {
                photo = videoFrame
                print("📸 [QuickVision] SDK capturePhoto failed, using video frame as fallback")
            } else {
                print("❌ [QuickVision] No photo or video frame available")
                throw QuickVisionError.frameTimeout
            }

            print("📸 [QuickVision] Photo captured: \(photo.size.width)x\(photo.size.height)")

            // 保存图片用于历史记录
            lastImage = photo

            // 5. 预配置 TTS 音频会话
            tts.prepareAudioSession()

            // 6. 立即停止视频流
            print("🛑 [QuickVision] Stopping stream after capture")
            await streamViewModel.stopSession()

            // 7. 调用识图 API
            let service = QuickVisionService(apiKey: apiKey)
            let result = try await service.analyzeImage(photo, customPrompt: prompt)

            // 8. 保存结果
            lastResult = result

            // 9. 保存到历史记录
            saveToHistory(mode: mode, prompt: prompt, result: result, image: photo)

            // 10. TTS 播报结果
            tts.speak(result, apiKey: apiKey)

            print("✅ [QuickVision] Complete: \(result)")

        } catch let error as QuickVisionError {
            errorMessage = error.localizedDescription
            print("❌ [QuickVision] QuickVisionError: \(error)")
            tts.speak(error.localizedDescription, apiKey: apiKey)
            await streamViewModel.stopSession()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuickVision] Error: \(error)")
            tts.speak("認識に失敗しました。\(error.localizedDescription)", apiKey: apiKey)
            await streamViewModel.stopSession()
        }

        isProcessing = false
    }

    /// 执行快速识图（使用当前设置的模式）
    func performQuickVision(customPrompt: String? = nil) async {
        await performQuickVisionWithMode(QuickVisionModeManager.staticCurrentMode, customPrompt: customPrompt)
    }

    /// 执行快速识图（从快捷指令/Siri 触发）
    func performQuickVisionFromIntent(customPrompt: String? = nil) async {
        await performQuickVision(customPrompt: customPrompt)
    }

    /// 保存识图结果到历史记录
    private func saveToHistory(mode: QuickVisionMode, prompt: String, result: String, image: UIImage) {
        let record = QuickVisionRecord(
            mode: mode,
            prompt: prompt,
            result: result,
            thumbnail: image
        )
        QuickVisionStorage.shared.saveRecord(record)
        print("💾 [QuickVision] Record saved to history")
    }

    /// 停止视频流（在页面关闭时调用）
    func stopStream() async {
        await streamViewModel?.stopSession()
    }

    /// 手动触发快速识图（从 UI 调用）
    func triggerQuickVision(customPrompt: String? = nil) {
        Task { @MainActor in
            await performQuickVision(customPrompt: customPrompt)
        }
    }

    /// 手动触发指定模式的快速识图（从 UI 调用）
    func triggerQuickVisionWithMode(_ mode: QuickVisionMode) {
        Task { @MainActor in
            await performQuickVisionWithMode(mode)
        }
    }
}
