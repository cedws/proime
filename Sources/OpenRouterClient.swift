import Foundation

/// Network configuration constants
private enum NetworkConfig {
    static let requestTimeout: TimeInterval = 10
    static let resourceTimeout: TimeInterval = 60
    static let prewarmTimeout: TimeInterval = 5
}

/// Client for OpenRouter API with streaming support
class OpenRouterClient {
    static let shared = OpenRouterClient()

    private let baseURL = "https://openrouter.ai/api/v1"

    // Pre-warmed connection flag with thread-safe access
    private let connectionPrewarmLock = NSLock()
    private var connectionPrewarmed = false

    // Shared URLSession for connection pooling and HTTP/2
    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.default

        // Network performance optimizations
        config.httpMaximumConnectionsPerHost = 1
        config.timeoutIntervalForRequest = NetworkConfig.requestTimeout
        config.timeoutIntervalForResource = NetworkConfig.resourceTimeout

        // Enable HTTP/2 and connection reuse
        config.httpShouldUsePipelining = true
        config.urlCache = nil  // Disable caching for real-time responses

        // Reduce latency
        config.waitsForConnectivity = false  // Fail fast if no connectivity
        config.shouldUseExtendedBackgroundIdleMode = false

        return URLSession(configuration: config)
    }()

    /// Pre-warm the connection to OpenRouter for faster first request
    func prewarmConnection() {
        connectionPrewarmLock.lock()
        defer { connectionPrewarmLock.unlock() }

        guard !connectionPrewarmed else { return }
        connectionPrewarmed = true

        Task {
            guard let url = URL(string: "\(baseURL)/models") else { return }

            // Make a lightweight GET request to establish connection
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"  // Just headers, no body
            request.timeoutInterval = NetworkConfig.prewarmTimeout

            NSLog("OpenRouter: Pre-warming connection...")
            _ = try? await urlSession.data(for: request)
            NSLog("OpenRouter: Connection pre-warmed")
        }
    }

    /// Stream completion from OpenRouter
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
    ) {
        let settings = SettingsManager.shared

        guard let apiKey = settings.openRouterAPIKey, !apiKey.isEmpty else {
            onError(OpenRouterError.missingAPIKey)
            return
        }

        Task {
            do {
                try await performStreamingRequest(
                    apiKey: apiKey,
                    model: settings.selectedModel,
                    systemPrompt: settings.systemPrompt,
                    userPrompt: prompt,
                    temperature: settings.temperature,
                    onToken: onToken,
                    onComplete: onComplete,
                    onError: onError
                )
            } catch {
                onError(error)
            }
        }
    }

    private func performStreamingRequest(
        apiKey: String,
        model: String,
        systemPrompt: String,
        userPrompt: String,
        temperature: Double,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) async throws {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenRouterError.invalidURL
        }

        // Build request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt],
            ],
            "temperature": temperature,
            "stream": true,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenRouterError.invalidRequest
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("ProIME", forHTTPHeaderField: "X-Title")
        request.httpBody = jsonData

        // Perform streaming request using shared session for connection pooling
        NSLog("OpenRouter: Starting request...")
        let requestStart = Date()
        let (bytes, response) = try await urlSession.bytes(for: request)
        let connectionTime = Date().timeIntervalSince(requestStart)
        NSLog("OpenRouter: Connection established in \(String(format: "%.3f", connectionTime))s")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            NSLog("OpenRouter: HTTP error \(httpResponse.statusCode)")
            throw OpenRouterError.httpError(statusCode: httpResponse.statusCode)
        }

        var fullText = ""
        var tokenCount = 0
        let streamStart = Date()

        // Process SSE stream
        for try await line in bytes.lines {
            NSLog("OpenRouter: Received line: \(line)")

            // SSE format: "data: {...}"
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))

                // Check for stream end
                if jsonString == "[DONE]" {
                    NSLog(
                        "OpenRouter: Stream completed with \(tokenCount) tokens in \(String(format: "%.3f", Date().timeIntervalSince(streamStart)))s"
                    )
                    break
                }

                // Parse JSON chunk
                if let jsonData = jsonString.data(using: .utf8),
                    let chunk = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                    let choices = chunk["choices"] as? [[String: Any]],
                    let firstChoice = choices.first,
                    let delta = firstChoice["delta"] as? [String: Any],
                    let content = delta["content"] as? String
                {
                    // Only process non-empty content
                    guard !content.isEmpty else {
                        NSLog("OpenRouter: Skipping empty content chunk")
                        continue
                    }

                    tokenCount += 1
                    if tokenCount == 1 {
                        let firstTokenTime = Date().timeIntervalSince(streamStart)
                        NSLog(
                            "OpenRouter: First token received in \(String(format: "%.3f", firstTokenTime))s"
                        )
                    }

                    fullText += content

                    // Call token callback on main thread
                    DispatchQueue.main.async {
                        onToken(content)
                    }
                } else {
                    NSLog("OpenRouter: Failed to parse JSON or no content in delta")
                }
            }
        }

        // Call completion callback on main thread
        DispatchQueue.main.async {
            onComplete(fullText)
        }
    }
}

/// Errors specific to OpenRouter API
enum OpenRouterError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidRequest
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenRouter API key not configured. Please open Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidRequest:
            return "Failed to create API request"
        case .invalidResponse:
            return "Invalid API response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}
