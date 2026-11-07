/*
 * Quick Vision Service
 * 快速识图服务 - 支持多提供商 (阿里云/OpenRouter)
 * 返回简洁的描述，适合 TTS 播报
 */

import Foundation
import UIKit

class QuickVisionService {
    private let apiKey: String
    private let baseURL: String
    private let model: String
    private let session: URLSession

    /// Initialize with explicit configuration
    init(apiKey: String, baseURL: String? = nil, model: String? = nil, session: URLSession = .shared) {
        self.session = session
        self.apiKey = apiKey
        self.baseURL = baseURL ?? VisionAPIConfig.baseURL
        self.model = model ?? VisionAPIConfig.model
    }

    /// Initialize with current provider configuration
    convenience init() {
        self.init(
            apiKey: VisionAPIConfig.apiKey,
            baseURL: VisionAPIConfig.baseURL,
            model: VisionAPIConfig.model
        )
    }

    // MARK: - API Request/Response Models

    struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [Message]
        var stream = true

        struct Message: Codable {
            let role: String
            let content: [Content]

            struct Content: Codable {
                let type: String
                let text: String?
                let imageUrl: ImageURL?

                enum CodingKeys: String, CodingKey {
                    case type
                    case text
                    case imageUrl = "image_url"
                }

                struct ImageURL: Codable {
                    let url: String
                }
            }
        }
    }

    struct ChatCompletionResponse: Codable {
        let choices: [Choice]?
        let error: APIError?

        struct Choice: Codable {
            let message: Message?
            let delta: Delta?
            let finish_reason: String?

            struct Message: Codable {
                let content: String?
            }

            struct Delta: Codable {
                let content: String?
            }
        }

        struct APIError: Codable {
            let message: String?

        }
    }

    // MARK: - Quick Vision Analysis

    /// 快速识图 - 返回简洁的语音描述
    /// - Parameters:
    ///   - image: 要识别的图片
    ///   - customPrompt: 自定义提示词（可选，如果为 nil 则使用当前模式的提示词）
    /// - Returns: 简洁的描述文本，适合 TTS 播报
    func analyzeImage(_ image: UIImage, customPrompt: String? = nil,
                      purpose: ImageUploadPreparation.Purpose = .document,
                      onDelta: @escaping @MainActor (String) -> Void = { _ in }) async throws -> String {
        guard !apiKey.isEmpty else {
            throw QuickVisionError.apiError(statusCode: 401, message: "設定でOpenAI APIキーを登録してください")
        }
        let prepared = await Task.detached(priority: .userInitiated) {
            ImageUploadPreparation.jpeg(image, purpose: purpose)
        }.value
        try Task.checkCancellation()
        guard let imageData = prepared else {
            throw QuickVisionError.invalidImage
        }

        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"

        // 使用自定义提示词、模式管理器的提示词、或默认提示词
        let prompt = customPrompt ?? QuickVisionModeManager.staticPrompt

        // Create API request
        let request = ChatCompletionRequest(
            model: model,
            messages: [
                ChatCompletionRequest.Message(
                    role: "user",
                    content: [
                        ChatCompletionRequest.Message.Content(
                            type: "image_url",
                            text: nil,
                            imageUrl: ChatCompletionRequest.Message.Content.ImageURL(url: dataURL)
                        ),
                        ChatCompletionRequest.Message.Content(
                            type: "text",
                            text: prompt,
                            imageUrl: nil
                        )
                    ]
                )
            ]
        )

        // Make API call
        return try await makeRequest(request, onDelta: onDelta)
    }

    // MARK: - Private Methods

    private func makeRequest(_ request: ChatCompletionRequest,
                             onDelta: @escaping @MainActor (String) -> Void) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw QuickVisionError.invalidResponse
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        for (key, value) in VisionAPIConfig.headers(with: apiKey) {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.timeoutInterval = 60
        urlRequest.httpBody = try JSONEncoder().encode(request)
        let (bytes, response) = try await session.bytes(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw QuickVisionError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw QuickVisionError.apiError(statusCode: http.statusCode, message: "画像認識との通信に失敗しました")
        }
        // Some compatible endpoints send a single JSON response even with stream enabled.
        if http.value(forHTTPHeaderField: "Content-Type")?.contains("application/json") == true {
            var data = Data()
            for try await byte in bytes { try Task.checkCancellation(); data.append(byte) }
            let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            if let error = completion.error {
                throw QuickVisionError.apiError(statusCode: -1, message: error.message ?? "画像認識に失敗しました")
            }
            guard let text = completion.choices?.first?.message?.content,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw QuickVisionError.emptyResponse
            }
            try Task.checkCancellation()
            await onDelta(text)
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var events = VisionEventBuffer()
        var text = ""
        var completed = false
        func consume(_ event: String) async throws {
            try Task.checkCancellation()
            if event == "[DONE]" { completed = true; return }
            let chunk = try JSONDecoder().decode(ChatCompletionResponse.self, from: Data(event.utf8))
            if let error = chunk.error {
                throw QuickVisionError.apiError(statusCode: -1, message: error.message ?? "画像認識に失敗しました")
            }
            guard let choice = chunk.choices?.first else { return }
            if let delta = choice.delta?.content, !delta.isEmpty {
                text += delta
                await onDelta(delta)
            }
            if let reason = choice.finish_reason {
                guard reason == "stop" else { throw QuickVisionError.invalidResponse }
                completed = true
            }
        }
        for try await line in bytes.lines {
            if let event = events.append(line) {
                try await consume(event)
                if event == "[DONE]" { break }
            }
        }
        if let event = events.finishEvent() { try await consume(event) }
        try Task.checkCancellation()
        guard completed else { throw QuickVisionError.invalidResponse }
        let result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { throw QuickVisionError.emptyResponse }
        return result
    }

}

// MARK: - Error Types

enum QuickVisionError: LocalizedError {
    case noDevice
    case streamNotReady
    case frameTimeout
    case invalidImage
    case emptyResponse
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .noDevice:
            return "グラスが未接続です。Meta AIアプリでペアリングしてください"
        case .streamNotReady:
            return "映像を開始できません。グラスの接続を確認してください"
        case .frameTimeout:
            return "映像の取得がタイムアウトしました。再試行してください"
        case .invalidImage:
            return "画像を処理できません"
        case .emptyResponse:
            return "AIから応答がありません。再試行してください"
        case .invalidResponse:
            return "応答形式が無効です"
        case .apiError(let statusCode, let message):
            return "APIエラー (\(statusCode)): \(message)"
        }
    }
}
