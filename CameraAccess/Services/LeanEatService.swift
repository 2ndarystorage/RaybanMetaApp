/*
 * LeanEat Service
 * 食物营养分析AI服务
 */

import Foundation
import UIKit

class LeanEatService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let model = "gpt-4.1-mini"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - API Request/Response Models

    struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [Message]

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
        let choices: [Choice]

        struct Choice: Codable {
            let message: Message

            struct Message: Codable {
                let content: String
            }
        }
    }

    // MARK: - Nutrition Analysis

    func analyzeFood(_ image: UIImage) async throws -> FoodNutritionResponse {
        guard !apiKey.isEmpty else {
            throw LeanEatError.apiError(statusCode: 401, message: "設定でOpenAI APIキーを登録してください")
        }
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw LeanEatError.invalidImage
        }

        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"

        // Create specialized nutrition analysis prompt
        let nutritionPrompt = """
あなたは栄養士のAIです。画像の食品を分析し、栄養情報をJSONのみで返してください。

**必ずJSONのみを返し、追加の文章を含めないでください。**
**nameやsuggestionsなど、文字列の値はすべて日本語にしてください。**

JSON形式：
{
  "foods": [
    {
      "name": "食品名（日本語）",
      "portion": "分量（例：1杯、100g）",
      "calories": カロリー（整数、kcal）,
      "protein": タンパク質（数値、g）,
      "fat": 脂質（数値、g）,
      "carbs": 炭水化物（数値、g）,
      "fiber": 食物繊維（数値、g、省略可）,
      "sugar": 糖質（数値、g、省略可）,
      "health_rating": "評価（優秀/良好/普通/要改善）"
    }
  ],
  "total_calories": 総カロリー（整数）,
  "total_protein": タンパク質合計（数値）,
  "total_fat": 脂質合計（数値）,
  "total_carbs": 炭水化物合計（数値）,
  "health_score": 健康スコア（0～100の整数）,
  "suggestions": [
    "栄養アドバイス1",
    "栄養アドバイス2",
    "栄養アドバイス3"
  ]
}

上記のJSON形式に従い、説明文は追加しないでください。
"""

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
                            text: nutritionPrompt,
                            imageUrl: nil
                        )
                    ]
                )
            ]
        )

        // Make API call
        let responseText = try await makeRequest(request)

        // Parse JSON response
        return try parseNutritionResponse(responseText)
    }

    // MARK: - Private Methods

    private func makeRequest(_ request: ChatCompletionRequest) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LeanEatError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LeanEatError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ChatCompletionResponse.self, from: data)

        guard let firstChoice = apiResponse.choices.first else {
            throw LeanEatError.emptyResponse
        }

        return firstChoice.message.content
    }

    private func parseNutritionResponse(_ text: String) throws -> FoodNutritionResponse {
        // Extract JSON from response (in case AI added extra text)
        var jsonText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to find JSON object in the response
        if let jsonStart = jsonText.range(of: "{"),
           let jsonEnd = jsonText.range(of: "}", options: .backwards) {
            jsonText = String(jsonText[jsonStart.lowerBound...jsonEnd.upperBound])
        }

        guard let jsonData = jsonText.data(using: .utf8) else {
            throw LeanEatError.invalidJSON
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(FoodNutritionResponse.self, from: jsonData)
        } catch {
            print("❌ [LeanEat] JSON解析失败: \(error)")
            print("📝 [LeanEat] 原始响应: \(text)")
            throw LeanEatError.invalidJSON
        }
    }
}

// MARK: - Error Types

enum LeanEatError: LocalizedError {
    case invalidImage
    case emptyResponse
    case invalidResponse
    case invalidJSON
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "画像を処理できません"
        case .emptyResponse:
            return "APIから応答がありません"
        case .invalidResponse:
            return "応答形式が無効です"
        case .invalidJSON:
            return "栄養データを解析できません。再試行してください"
        case .apiError(let statusCode, let message):
            return "APIエラー (\(statusCode)): \(message)"
        }
    }
}
