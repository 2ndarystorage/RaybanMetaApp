import AVFoundation
import Observation
import UIKit

@Observable
@MainActor
final class BookReaderModel {
  var summary = ""
  var errorMessage: String?
  var isWorking = false
  var sourceImage: UIImage?
  @ObservationIgnored private var task: Task<Void, Never>?
  @ObservationIgnored private var requestID = UUID()
  @ObservationIgnored private let speech = AVSpeechSynthesizer()

  @ObservationIgnored private let summarize: (UIImage, String, Int) async throws -> String
  @ObservationIgnored private let readAPIKey: () -> String

  init(
    readAPIKey: @escaping () -> String = { APIKeyManager.shared.getOpenAIAPIKey() ?? "" },
    summarize: @escaping (UIImage, String, Int) async throws -> String = { image, key, limit in
      try await BookSummaryService().summarize(image: image, apiKey: key, limit: limit)
    }
  ) {
    self.readAPIKey = readAPIKey
    self.summarize = summarize
  }

  func read(image: UIImage, limit: Int) {
    guard !isWorking else { return }
    let key = readAPIKey().trimmingCharacters(in: .whitespacesAndNewlines)
    guard !key.isEmpty else {
      errorMessage = "設定からご自身のOpenAI APIキーを入力してください。"
      return
    }
    speech.stopSpeaking(at: .immediate)
    sourceImage = image
    summary = ""
    errorMessage = nil
    isWorking = true
    let id = UUID()
    requestID = id
    let summarize = self.summarize
    task = Task { [weak self] in
      do {
        let result = try await summarize(image, key, limit)
        try Task.checkCancellation()
        guard let self, self.requestID == id else { return }
        self.summary = result
        self.isWorking = false
        self.task = nil
        self.play()
      } catch {
        guard let self, self.requestID == id else { return }
        self.isWorking = false
        self.task = nil
        if !Task.isCancelled { self.errorMessage = error.localizedDescription }
      }
    }
  }

  func play() {
    guard !summary.isEmpty else { return }
    do {
      let audio = AVAudioSession.sharedInstance()
      try audio.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
      try audio.setActive(true)
      speech.stopSpeaking(at: .immediate)
      let utterance = AVSpeechUtterance(string: summary)
      utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
      utterance.rate = AVSpeechUtteranceDefaultSpeechRate
      speech.speak(utterance)
    } catch {
      errorMessage = "音声を再生できませんでした：\(error.localizedDescription)"
    }
  }

  func stop() {
    requestID = UUID()
    task?.cancel()
    task = nil
    isWorking = false
    speech.stopSpeaking(at: .immediate)
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
