/*
 * Vision Recognition ViewModel
 * Manages image recognition state and API interaction
 */

import Foundation
import SwiftUI

@MainActor
class VisionRecognitionViewModel: ObservableObject {
    // Published properties for UI
    @Published var isAnalyzing = false
    @Published var recognitionResult: String?
    @Published var errorMessage: String?
    @Published var customPrompt: String = "画像には何が写っていますか？日本語で説明してください。"

    private let apiService: VisionAPIService
    private let photo: UIImage

    init(photo: UIImage, apiKey: String) {
        self.photo = photo
        self.apiService = VisionAPIService(apiKey: apiKey)
    }

    // MARK: - Public Methods

    func analyzeImage(with prompt: String? = nil) async {
        isAnalyzing = true
        errorMessage = nil
        recognitionResult = nil

        do {
            let promptToUse = prompt ?? customPrompt
            let result = try await apiService.analyzeImage(photo, prompt: promptToUse)
            recognitionResult = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    func retryAnalysis() async {
        await analyzeImage()
    }

    func clearResult() {
        recognitionResult = nil
        errorMessage = nil
    }

    // MARK: - Quick Prompts

    static let quickPrompts = [
        "画像には何が写っていますか？",
        "この画像を詳しく説明してください",
        "どのような物がありますか？",
        "この画像を日本語で説明してください",
        "ここはどこですか？",
        "写っている人は何をしていますか？"
    ]
}
