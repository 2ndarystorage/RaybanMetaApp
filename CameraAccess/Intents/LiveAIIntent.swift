/*
 * Live AI Intent
 * App Intent - 支持 Siri 和快捷指令触发 Live AI（后台运行，无需解锁）
 */

import AppIntents
import UIKit

// MARK: - Live AI Intent (Background Mode)

@available(iOS 16.0, *)
struct LiveAIIntent: AppIntent {
    static var title: LocalizedStringResource = "リアルタイム会話"
    static var description = IntentDescription("リアルタイムのマルチモーダル会話を開始します")
    // 必须打开 App，因为 iOS 后台录音有系统限制
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 发送通知让 App 自动打开 Live AI 界面
        NotificationCenter.default.post(name: .liveAITriggered, object: nil)
        return .result(dialog: "リアルタイム会話を開始しています…")
    }
}

// MARK: - Stop Live AI Intent

@available(iOS 16.0, *)
struct StopLiveAIIntent: AppIntent {
    static var title: LocalizedStringResource = "会話を停止"
    static var description = IntentDescription("実行中のリアルタイム会話を停止します")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = LiveAIManager.shared

        if manager.isRunning {
            await manager.stopSession()
            return .result(dialog: "Live AIを停止しました")
        } else {
            return .result(dialog: "Live AIは実行されていません")
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let liveAITriggered = Notification.Name("liveAITriggered")
}
