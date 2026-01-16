import Foundation

/// Protocol defining the interface for LLM providers
protocol LLMProvider {
    /// Stream completion from the LLM
    /// - Parameters:
    ///   - prompt: User's input text
    ///   - onToken: Callback for each token received
    ///   - onComplete: Callback when streaming completes
    ///   - onError: Callback for errors
    func streamCompletion(
        prompt: String,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    )

    /// Pre-warm the connection for faster first request
    func prewarmConnection()
}

/// Available LLM provider types
enum LLMProviderType: String, Codable, CaseIterable {
    case openRouter = "openrouter"
    case githubModels = "github"

    var displayName: String {
        switch self {
        case .openRouter:
            return "OpenRouter"
        case .githubModels:
            return "GitHub Models"
        }
    }
}

/// Factory for getting the appropriate LLM provider
enum LLMProviderFactory {
    static func provider(for type: LLMProviderType) -> LLMProvider {
        switch type {
        case .openRouter:
            return OpenRouterClient.shared
        case .githubModels:
            return GitHubModelsClient.shared
        }
    }

    static var current: LLMProvider {
        provider(for: SettingsManager.shared.selectedProvider)
    }
}
