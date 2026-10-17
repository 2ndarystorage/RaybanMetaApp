/*
 * Simple Live Stream View
 * 简化的直播视图 - 用于抖音/快手等平台
 */

import SwiftUI

struct SimpleLiveStreamView: View {
    @ObservedObject var streamViewModel: StreamSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showUI = true // 控制 UI 显示/隐藏

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .edgesIgnoringSafeArea(.all)

            // Video feed
            if let videoFrame = streamViewModel.currentVideoFrame {
                GeometryReader { geometry in
                    Image(uiImage: videoFrame)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: AppSpacing.lg) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                    Text("映像に接続中…")
                        .font(AppTypography.body)
                        .foregroundColor(.white)
                }
            }

            // UI 元素 - 点击屏幕可隐藏
            if showUI {
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                        }

                        Spacer()

                        // Status indicator
                        HStack(spacing: AppSpacing.sm) {
                            Circle()
                                .fill(streamViewModel.isStreaming ? Color.red : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(streamViewModel.isStreaming ? "配信中" : "未接続")
                                .font(AppTypography.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(AppCornerRadius.lg)
                        .padding(AppSpacing.md)
                    }

                    Spacer()

                    // Instructions
                    VStack(spacing: AppSpacing.md) {
                        Text("配信の手順")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)

                        Text("1. 配信プラットフォームを開く")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.8))

                        Text("2. 画面収録を選択する")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.8))

                        Text("3. この画面の収録を始めて配信する")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(AppSpacing.lg)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(AppCornerRadius.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
                .transition(.opacity)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showUI.toggle()
            }
        }
        .onAppear {
            // 启动视频流
            Task {
                print("🎥 SimpleLiveStreamView: 启动视频流")
                await streamViewModel.handleStartStreaming()
            }
        }
        .onDisappear {
            // 停止视频流
            Task {
                print("🎥 SimpleLiveStreamView: 停止视频流")
                if streamViewModel.streamingStatus != .stopped {
                    await streamViewModel.stopSession()
                }
            }
        }
    }
}
