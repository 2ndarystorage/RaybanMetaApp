/*
 * Vision API Configuration
 * Centralized configuration for Vision API
 * Supports multiple providers: Alibaba Cloud Dashscope, OpenRouter
 */

import Foundation

struct VisionAPIConfig {
    // MARK: - Dynamic Configuration (based on current provider)

    /// Current API Key based on selected provider
    static var apiKey: String {
        return APIKeyManager.shared.getOpenAIAPIKey() ?? ""
    }

    /// Current Base URL based on selected provider
    static var baseURL: String {
        return "https://api.openai.com/v1"
    }

    /// Current Model based on selected provider
    static var model: String {
        return "gpt-4.1-mini"
    }

    // MARK: - Request Headers

    /// Get headers for the current provider
    static func headers(with apiKey: String) -> [String: String] {
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]

        return headers
    }
}
