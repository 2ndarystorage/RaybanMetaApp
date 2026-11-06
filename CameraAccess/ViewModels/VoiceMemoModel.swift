import AVFoundation
import Speech
import SwiftUI

@MainActor
final class VoiceMemoModel: ObservableObject {
    enum Phase { case idle, preparing, recording, finishing }
    @Published private(set) var phase: Phase = .idle
    @Published var text = ""
    @Published var useBluetooth = false
    @Published private(set) var inputName = ""
    @Published private(set) var memos: [VoiceMemo] = []
    @Published var message: String?
    @Published var errorMessage: String?
    var busy: Bool { phase != .idle }

    private let storage: VoiceMemoStorage
    private var memoID = UUID()
    private var createdAt = Date()
    private var generation = UUID()
    private var prefix = ""
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognizer: SFSpeechRecognizer?
    private var recognition: SFSpeechRecognitionTask?
    private var timer: Task<Void, Never>?
    private var finishTimer: Task<Void, Never>?
    private var sessionOwned = false

    init(storage: VoiceMemoStorage = VoiceMemoStorage()) {
        self.storage = storage
        reload()
    }

    func reload() {
        do { memos = try storage.load() }
        catch { errorMessage = "保存したメモを読み込めませんでした。\(error.localizedDescription)" }
    }

    func start() async {
        guard !busy else { return }
        phase = .preparing
        errorMessage = nil
        message = nil
        let token = UUID()
        generation = token
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard generation == token, phase == .preparing else { return }
        guard speech == .authorized else {
            phase = .idle
            errorMessage = "音声認識が許可されていません。iPhoneの設定で、このアプリの音声認識を許可してください。"
            return
        }
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard generation == token, phase == .preparing else { return }
        guard microphone else {
            phase = .idle
            errorMessage = "マイクが許可されていません。iPhoneの設定で、このアプリのマイクを許可してください。"
            return
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP")),
              recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            phase = .idle
            errorMessage = "日本語の端末内音声認識を利用できません。iPhoneの日本語の音声入力設定を確認してください。"
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothHFP, .defaultToSpeaker])
            try session.setActive(true)
            sessionOwned = true
            let port = session.availableInputs?.first { $0.portType == (useBluetooth ? .bluetoothHFP : .builtInMic) }
            guard let port else {
                throw NSError(domain: "VoiceMemo", code: 1, userInfo: [NSLocalizedDescriptionKey: useBluetooth ? "Bluetoothマイクが見つかりません。グラスの接続を確認するか、iPhoneのマイクを選んでください。" : "iPhoneのマイクを利用できません。"])
            }
            try session.setPreferredInput(port)
            inputName = port.portName
            prefix = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true
            request.addsPunctuation = true
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw NSError(domain: "VoiceMemo", code: 2, userInfo: [NSLocalizedDescriptionKey: "マイクの音声形式を取得できません。接続を確認してください。"])
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
            self.engine = engine
            self.request = request
            self.recognizer = recognizer
            phase = .recording
            recognition = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let recognized = result?.bestTranscription.formattedString
                let final = result?.isFinal == true
                let failed = error != nil
                Task { @MainActor in
                    guard let self, self.generation == token else { return }
                    if let recognized, !recognized.isEmpty {
                        self.text = self.prefix.isEmpty ? recognized : self.prefix + "\n" + recognized
                    }
                    if final || failed {
                        if failed && self.phase == .recording {
                            self.errorMessage = "音声認識が停止しました。認識できた内容を保存します。もう一度開始できます。"
                        }
                        self.finish()
                    }
                }
            }
            engine.prepare()
            try engine.start()
            timer = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 55_000_000_000)
                guard !Task.isCancelled else { return }
                self?.stop()
            }
        } catch {
            finish()
            errorMessage = error.localizedDescription
        }
    }

    /// Keep the request alive briefly to receive the final words after the tap stops.
    func stop() {
        guard phase != .idle else { return }
        if phase == .preparing {
            generation = UUID()
            phase = .idle
            return
        }
        guard phase != .finishing else { return }
        phase = .finishing
        timer?.cancel()
        stopInput()
        request?.endAudio()
        finishTimer = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.finish()
        }
    }

    /// Used when leaving the foreground: preserve the latest result and release the mic immediately.
    func suspend() {
        guard busy else { return }
        finish()
    }

    private func stopInput() {
        if let engine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        engine = nil
    }

    private func finish() {
        generation = UUID()
        timer?.cancel()
        finishTimer?.cancel()
        stopInput()
        request?.endAudio()
        recognition?.cancel()
        recognition = nil
        recognizer = nil
        request = nil
        if sessionOwned {
            let session = AVAudioSession.sharedInstance()
            try? session.setPreferredInput(nil)
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            sessionOwned = false
        }
        phase = .idle
        save()
    }

    @discardableResult
    func save() -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            message = "認識された文字はありません。"
            return true
        }
        do {
            if memos.first(where: { $0.id == memoID })?.text != clean {
                try storage.save(VoiceMemo(id: memoID, createdAt: createdAt, text: clean))
                memos = try storage.load()
            }
            message = "端末に保存しました。"
            return true
        } catch {
            errorMessage = "保存できませんでした。画面の文章をコピーして保管してください。\(error.localizedDescription)"
            return false
        }
    }

    func newMemo() {
        guard !busy else { return }
        // Do not discard edits if persistence fails.
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = nil
            guard save() else { return }
        }
        memoID = UUID()
        createdAt = Date()
        text = ""
        message = nil
    }

    func delete(_ memo: VoiceMemo) {
        do {
            try storage.delete(memo.id)
            memos = try storage.load()
            if memoID == memo.id {
                memoID = UUID()
                createdAt = Date()
                text = ""
                message = nil
            }
        } catch { errorMessage = "メモを削除できませんでした。\(error.localizedDescription)" }
    }
}
