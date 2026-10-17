/*
 * Live AI View
 * 自动启动的实时 AI 对话界面
 */

import SwiftUI
import Speech

struct LiveAIView: View {
    @StateObject private var viewModel: OmniRealtimeViewModel
    @ObservedObject var streamViewModel: StreamSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showConversation = true // 控制对话内容显示/隐藏
    @State private var frameTimer: Timer?
    @StateObject private var wakeListener = WakePhraseListener()

    init(streamViewModel: StreamSessionViewModel) {
        self.streamViewModel = streamViewModel
        // Use the Live AI API key based on selected provider
        let liveAIApiKey = APIProviderManager.staticLiveAIAPIKey
        self._viewModel = StateObject(wrappedValue: OmniRealtimeViewModel(apiKey: liveAIApiKey))
    }

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()

            // 未连接设备提醒
            if !streamViewModel.hasActiveDevice {
                deviceNotConnectedView
            } else {
                // Video feed (full opacity, no white mask)
                if let videoFrame = streamViewModel.currentVideoFrame {
                    GeometryReader { geometry in
                        Image(uiImage: videoFrame)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                // Header (紧贴状态栏)
                headerView
                    .padding(.top, 8) // 状态栏下方一点点

                // Conversation history (可隐藏)
                if showConversation {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.conversationHistory) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                // Current AI response (streaming)
                                if !viewModel.currentTranscript.isEmpty {
                                    MessageBubble(
                                        message: ConversationMessage(
                                            role: .assistant,
                                            content: viewModel.currentTranscript
                                        )
                                    )
                                    .id("current")
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.conversationHistory.count) { _ in
                            if let lastMessage = viewModel.conversationHistory.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.currentTranscript) { _ in
                            withAnimation {
                                proxy.scrollTo("current", anchor: .bottom)
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Spacer()
                }

                // Status and stop button
                controlsView
                }
            }
        }
        .onAppear {
            // 只有设备连接时才启动功能
            guard streamViewModel.hasActiveDevice else {
                print("⚠️ LiveAIView: 未连接RayBan Meta眼镜，跳过启动")
                return
            }

            // 启动视频流
            Task {
                print("🎥 LiveAIView: 启动视频流")
                await streamViewModel.handleStartStreaming()
            }

            if UserDefaults.standard.bool(forKey: "liveai_wake_enabled") {
                wakeListener.start {
                    viewModel.connect()
                }
            } else {
                viewModel.connect()
            }

            // 更新视频帧
            frameTimer?.invalidate()
            frameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let frame = streamViewModel.currentVideoFrame {
                    viewModel.updateVideoFrame(frame)
                }
            }
        }
        .onDisappear {
            // 停止 AI 对话和视频流
            print("🎥 LiveAIView: 停止 AI 对话和视频流")
            frameTimer?.invalidate()
            frameTimer = nil
            wakeListener.stop()
            viewModel.disconnect()
            Task {
                if streamViewModel.streamingStatus != .stopped {
                    await streamViewModel.stopSession()
                }
            }
        }
        .onChange(of: viewModel.isConnected) { isConnected in
            if isConnected, !viewModel.isRecording {
                viewModel.startRecording()
            }
        }
        .alert("error".localized, isPresented: $viewModel.showError) {
            Button("ok".localized) {
                viewModel.dismissError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("liveai.title".localized)
                .font(AppTypography.headline)
                .foregroundColor(.white)

            Spacer()

            // Hide/show conversation button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showConversation.toggle()
                }
            } label: {
                Image(systemName: showConversation ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
            }

            // Connection status
            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(viewModel.isConnected ? "liveai.connected".localized : "liveai.connecting".localized)
                    .font(AppTypography.caption)
                    .foregroundColor(.white)
            }

            // Speaking indicator
            if viewModel.isSpeaking {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "waveform")
                        .foregroundColor(.green)
                    Text("liveai.speaking".localized)
                        .font(AppTypography.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.black.opacity(0.7))
    }

    // MARK: - Controls

    private var controlsView: some View {
        VStack(spacing: AppSpacing.md) {
            if wakeListener.isListening {
                Text("Say Hey Turbo to start")
                    .foregroundColor(.white)
                Button("Start now") {
                    wakeListener.stop()
                    viewModel.connect()
                }
                .foregroundColor(.white)
            }
            if let error = wakeListener.errorMessage {
                Text(error).foregroundColor(.orange)
                Button("Start now") { viewModel.connect() }
                    .foregroundColor(.white)
            }
            // Recording status
            HStack(spacing: AppSpacing.sm) {
                if viewModel.isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("liveai.listening".localized)
                        .font(AppTypography.caption)
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                    Text("liveai.stop".localized)
                        .font(AppTypography.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.black.opacity(0.6))
            .cornerRadius(AppCornerRadius.xl)

            // Stop button (only button)
            Button {
                viewModel.disconnect()
                dismiss()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                    Text("liveai.stop".localized)
                        .font(AppTypography.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(AppCornerRadius.lg)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(.bottom, AppSpacing.lg)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Device Not Connected View

    private var deviceNotConnectedView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "eyeglasses")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.liveAI.opacity(0.6))

                Text("liveai.device.notconnected.title".localized)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)

                Text("liveai.device.notconnected.message".localized)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            Spacer()

            // Back button
            Button {
                dismiss()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "chevron.left")
                    Text("liveai.device.backtohome".localized)
                        .font(AppTypography.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.primary)
                .foregroundColor(.white)
                .cornerRadius(AppCornerRadius.lg)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
    }
}

@MainActor
final class WakePhraseListener: ObservableObject {
    @Published private(set) var isListening = false
    @Published private(set) var errorMessage: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isActive = false

    func start(onDetected: @escaping () -> Void) {
        errorMessage = nil
        isActive = true
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self, self.isActive else { return }
                guard status == .authorized,
                      let recognizer = self.recognizer,
                      recognizer.isAvailable,
                      recognizer.supportsOnDeviceRecognition else {
                    self.errorMessage = "On-device speech recognition is unavailable. Tap Start now."
                    return
                }
                self.beginRecognition(recognizer: recognizer, onDetected: onDetected)
            }
        }
    }

    private func beginRecognition(recognizer: SFSpeechRecognizer, onDetected: @escaping () -> Void) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true
            let input = engine.inputNode
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
                request.append(buffer)
            }
            self.engine = engine
            self.request = request
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self, self.isListening else { return }
                    if let text = result?.bestTranscription.formattedString.lowercased(),
                       text.contains("hey turbo") {
                        self.stop()
                        onDetected()
                    } else if error != nil {
                        self.stop()
                        self.errorMessage = "Wake phrase listening stopped. Tap Start now."
                    }
                }
            }
            engine.prepare()
            try engine.start()
            isListening = true
        } catch {
            stop()
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        isActive = false
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
        engine = nil
        isListening = false
    }
}
