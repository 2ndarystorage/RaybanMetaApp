import SwiftUI

/// Uses the app's shared DAT session and OpenAI key; no separate device registration.
struct BookReaderView: View {
    @ObservedObject var streamViewModel: StreamSessionViewModel
    @State private var reader = BookReaderModel()
    @State private var isChangingStream = false
    @State private var isVisible = false
    @State private var streamTask: Task<Void, Never>?
    @AppStorage("summary-character-limit") private var limit = 200
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    private var canRead: Bool {
        scenePhase == .active && !isChangingStream &&
        streamViewModel.streamingStatus == .streaming &&
        streamViewModel.hasReceivedFirstFrame && streamViewModel.currentVideoFrame != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("本を見て、短く聴く")
                        .font(AppTypography.title2)
                    Text("明るい場所で読みたいページを正面に向け、文字がはっきり映ることを確認してください。")
                        .foregroundStyle(.secondary)
                    preview
                    Label(streamViewModel.streamingStatus == .streaming ? "映像受信中" : "映像停止・待機中", systemImage: "eyeglasses")
                        .font(.caption)
                    Button(streamViewModel.isStreaming ? "映像を停止" : "映像を開始") {
                        changeStream()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isChangingStream || scenePhase != .active)

                    if streamViewModel.showError {
                        Text(streamViewModel.errorMessage).foregroundStyle(.red)
                    }
                    Stepper("要約は\(limit)文字以内", value: $limit, in: 50...1000, step: 50)
                        .disabled(reader.isWorking)
                    Button {
                        guard canRead, let image = streamViewModel.currentVideoFrame else { return }
                        reader.read(image: image, limit: limit)
                    } label: {
                        Label(reader.isWorking ? "読み取り・要約中…" : "このページを要約", systemImage: "book.closed")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(reader.isWorking || !canRead)
                    if reader.isWorking {
                        HStack {
                            ProgressView()
                            Button("キャンセル") { reader.stop() }
                        }
                    }
                    if let error = reader.errorMessage {
                        Text(error).foregroundStyle(.red)
                    }
                    if !reader.summary.isEmpty {
                        summaryCard
                    }
                    Text("設定に保存したOpenAI APIキーを使います。要約ボタンを押した時点の画像をOpenAIへ送信し、画像や本文はファイルに保存しません。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("音声は日本語で、iPhoneの現在の音声出力先に再生します。メガネから聴く場合は音声出力先を確認してください。画面を閉じる・バックグラウンドに移ると要約と読み上げを停止します。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(AppColors.secondaryBackground)
            .navigationTitle("本の要約")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        isVisible = false
                        stop()
                        let pending = streamTask
                        Task { @MainActor in
                            await pending?.value
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            isVisible = true
            limit = min(1000, max(50, limit))
        }
        .onDisappear {
            if isVisible {
                isVisible = false
                stop()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { stop() }
        }
        .onChange(of: streamViewModel.streamingStatus) { _, status in
            // Also cancels an in-flight request if glasses disconnect or pause.
            if status != .streaming { reader.stop() }
        }
        .onChange(of: streamViewModel.hasActiveDevice) { _, connected in
            if !connected { stop() }
        }
    }

    private var preview: some View {
        ZStack {
            Color.black
            if canRead, let image = streamViewModel.currentVideoFrame {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed").font(.largeTitle)
                    Text("映像を開始して、本のページを映してください")
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
        .accessibilityLabel("メガネのカメラ映像")
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("要約 · \(reader.summary.count)文字").font(.headline)
            if let image = reader.sourceImage {
                Image(uiImage: image)
                    .resizable().scaledToFit().frame(maxHeight: 160)
                    .accessibilityLabel("この要約に使ったページ")
            }
            Text(reader.summary).textSelection(.enabled)
            HStack {
                Button("もう一度聴く") { reader.play() }
                Button("読み上げ停止") { reader.stop() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppCornerRadius.lg))
    }

    private func changeStream() {
        reader.stop()
        streamViewModel.dismissError()
        isChangingStream = true
        let wasStreaming = streamViewModel.isStreaming
        streamTask = Task { @MainActor in
            if wasStreaming {
                await streamViewModel.stopSession()
            } else {
                await streamViewModel.handleStartStreaming()
                // Permission prompts/session startup may complete after leaving this screen.
                if Task.isCancelled || !isVisible || scenePhase != .active {
                    await streamViewModel.stopSession()
                }
            }
            isChangingStream = false
        }
    }

    private func stop() {
        reader.stop()
        let pending = streamTask
        pending?.cancel()
        isChangingStream = true
        streamTask = Task { @MainActor in
            await pending?.value
            await streamViewModel.stopSession()
            isChangingStream = false
        }
    }
}
