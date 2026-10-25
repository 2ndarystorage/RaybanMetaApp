/*
 * TurboMeta Home View
 * 主页 - 功能入口
 */

import SwiftUI

struct TurboMetaHomeView: View {
    @ObservedObject var streamViewModel: StreamSessionViewModel
    @ObservedObject var wearablesViewModel: WearablesViewModel
    @StateObject private var quickVisionManager = QuickVisionManager.shared
    @StateObject private var liveAIManager = LiveAIManager.shared

    @AppStorage(HomeAccessibilitySettings.storageKey) private var accessibilityMode = false

    @State private var showLiveAI = false
    @State private var showLeanEat = false
    @State private var showQuickVision = false
    @State private var showLiveTranslate = false
    @State private var showBookReader = false

    var body: some View {
        NavigationView {
            UrbanHomeDashboard(isConnected: streamViewModel.hasActiveDevice) { action in
                switch action {
                case .liveAI: showLiveAI = true
                case .quickVision: showQuickVision = true
                case .translation: showLiveTranslate = true
                case .leanEat: showLeanEat = true
                case .book: showBookReader = true
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showLiveAI) {
                LiveAIView(streamViewModel: streamViewModel)
            }
            .fullScreenCover(isPresented: $showLeanEat) {
                StreamView(viewModel: streamViewModel, wearablesVM: wearablesViewModel)
            }
            .fullScreenCover(isPresented: $showQuickVision) {
                QuickVisionView(streamViewModel: streamViewModel)
            }
            .fullScreenCover(isPresented: $showBookReader) {
                BookReaderView(streamViewModel: streamViewModel)
            }
            .fullScreenCover(isPresented: $showLiveTranslate) {
                LiveTranslateView(streamViewModel: streamViewModel)
            }
        }
        .preferredColorScheme(accessibilityMode ? nil : .light)
        .onAppear {
            // 确保 QuickVisionManager 有 streamViewModel 引用
            quickVisionManager.setStreamViewModel(streamViewModel)
            // 确保 LiveAIManager 有 streamViewModel 引用
            liveAIManager.setStreamViewModel(streamViewModel)

        }
        .onReceive(NotificationCenter.default.publisher(for: .liveAITriggered)) { _ in
            // 从快捷指令触发，自动打开 Live AI 界面
            showLiveAI = true
        }
    }
}
