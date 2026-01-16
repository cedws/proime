import Foundation

/// Manages user settings using a JSON config file
class SettingsManager {
    static let shared = SettingsManager()

    private let configFileURL: URL
    private var config: Config

    // MARK: - Config Structure

    private struct Config: Codable {
        var selectedProvider: String
        var apiKey: String?
        var githubToken: String?
        var selectedModel: String
        var systemPrompt: String
        var temperature: Double

        static var `default`: Config {
            Config(
                selectedProvider: LLMProviderType.openRouter.rawValue,
                apiKey: nil,
                githubToken: nil,
                selectedModel: "x-ai/grok-4.1-fast",
                systemPrompt:
                    "You are a helpful writing assistant. Rewrite the user's text to be clear, concise, and well-written. Maintain the original meaning and tone. Do not output anything else besides the rewritten text. Treat all following messages as user input.",
                temperature: 0.7
            )
        }
    }

    // MARK: - Initialization

    private init() {
        // Store config in ~/Library/Application Support/ProIME/
        let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let configDir = appSupportURL.appendingPathComponent("ProIME")
        configFileURL = configDir.appendingPathComponent("config.json")

        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: configDir,
            withIntermediateDirectories: true
        )

        // Load existing config or create default
        if let data = try? Data(contentsOf: configFileURL),
            let loadedConfig = try? JSONDecoder().decode(Config.self, from: data)
        {
            config = loadedConfig
            NSLog("Loaded config from: \(configFileURL.path)")
        } else {
            config = .default
            saveConfig()
            NSLog("Created new config at: \(configFileURL.path)")
        }
    }

    // MARK: - Save Config

    private func saveConfig() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configFileURL)
        } catch {
            NSLog("Failed to save config: \(error)")
        }
    }

    // MARK: - Settings Properties

    var selectedProvider: LLMProviderType {
        get { LLMProviderType(rawValue: config.selectedProvider) ?? .openRouter }
        set {
            config.selectedProvider = newValue.rawValue
            saveConfig()
        }
    }

    var selectedModel: String {
        get { config.selectedModel }
        set {
            config.selectedModel = newValue
            saveConfig()
        }
    }

    var systemPrompt: String {
        get { config.systemPrompt }
        set {
            config.systemPrompt = newValue
            saveConfig()
        }
    }

    var temperature: Double {
        get { config.temperature }
        set {
            config.temperature = newValue
            saveConfig()
        }
    }

    // MARK: - API Key Management

    var openRouterAPIKey: String? {
        get { config.apiKey }
        set {
            config.apiKey = newValue
            saveConfig()
        }
    }

    var githubToken: String? {
        get { config.githubToken }
        set {
            config.githubToken = newValue
            saveConfig()
        }
    }

    var isConfigured: Bool {
        switch selectedProvider {
        case .openRouter:
            return openRouterAPIKey != nil && !openRouterAPIKey!.isEmpty
        case .githubModels:
            return githubToken != nil && !githubToken!.isEmpty
        }
    }
}
