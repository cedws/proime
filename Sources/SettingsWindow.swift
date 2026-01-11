import AppKit
import SwiftUI

struct OpenRouterModel: Codable, Identifiable {
    let id: String
    let name: String?

    var displayName: String {
        name ?? id
    }
}

struct ModelsResponse: Codable {
    let data: [OpenRouterModel]
}

/// SwiftUI view for settings configuration
struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var selectedModel: String = ""
    @State private var customModel: String = ""
    @State private var systemPrompt: String = ""
    @State private var temperature: Double = 0.7
    @State private var showingAPIKey: Bool = false
    @State private var saveStatus: String = ""
    @State private var availableModels: [OpenRouterModel] = []
    @State private var isLoadingModels = false
    @State private var useCustomModel = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("ProIME Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // API Key Section
                    GroupBox(label: Label("OpenRouter API Key", systemImage: "key.fill")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                if showingAPIKey {
                                    TextField("sk-or-v1-...", text: $apiKey)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    SecureField("sk-or-v1-...", text: $apiKey)
                                        .textFieldStyle(.roundedBorder)
                                }

                                Button(action: { showingAPIKey.toggle() }) {
                                    Image(systemName: showingAPIKey ? "eye.slash.fill" : "eye.fill")
                                }
                                .buttonStyle(.plain)
                            }

                            Text(
                                "Get your API key from [openrouter.ai](https://openrouter.ai/keys)"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(8)
                    }

                    // Model Selection
                    GroupBox(label: Label("Model", systemImage: "cpu")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Toggle("Custom model", isOn: $useCustomModel)
                                    .toggleStyle(.checkbox)
                                Spacer()
                                if !useCustomModel {
                                    Button("Refresh Models") {
                                        loadModelsFromAPI()
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isLoadingModels)
                                }
                            }

                            if useCustomModel {
                                TextField(
                                    "Enter model ID (e.g., x-ai/grok-4.1-fast)", text: $customModel
                                )
                                .textFieldStyle(.roundedBorder)
                            } else {
                                if isLoadingModels {
                                    ProgressView()
                                        .progressViewStyle(.linear)
                                } else if availableModels.isEmpty {
                                    Text("Click 'Refresh Models' to load from OpenRouter")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Picker("", selection: $selectedModel) {
                                        ForEach(availableModels) { model in
                                            Text(model.displayName).tag(model.id)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                }
                            }

                            Text("Choose the LLM model for text transformation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                    }

                    // System Prompt
                    GroupBox(label: Label("System Prompt", systemImage: "text.quote")) {
                        VStack(alignment: .leading, spacing: 10) {
                            TextEditor(text: $systemPrompt)
                                .frame(minHeight: 100)
                                .font(.system(.body, design: .monospaced))
                                .border(Color.gray.opacity(0.2))

                            Text("Instructions for how the AI should transform your text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                    }

                    // Temperature
                    GroupBox(label: Label("Temperature", systemImage: "thermometer.medium")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Slider(value: $temperature, in: 0...2, step: 0.1)
                                Text(String(format: "%.1f", temperature))
                                    .frame(width: 40)
                                    .font(.system(.body, design: .monospaced))
                            }

                            HStack {
                                Text("More focused")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("More creative")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(8)
                    }

                    // Save Status
                    if !saveStatus.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(saveStatus)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }

            // Footer with buttons
            HStack {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)

                Spacer()

                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 600, height: 650)
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        let settings = SettingsManager.shared
        apiKey = settings.openRouterAPIKey ?? ""

        let currentModel = settings.selectedModel
        selectedModel = currentModel
        customModel = currentModel

        systemPrompt = settings.systemPrompt
        temperature = settings.temperature
    }

    private func loadModelsFromAPI() {
        isLoadingModels = true

        Task {
            do {
                guard let url = URL(string: "https://openrouter.ai/api/v1/models") else { return }

                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(ModelsResponse.self, from: data)

                await MainActor.run {
                    availableModels = response.data.sorted { $0.id < $1.id }
                    isLoadingModels = false

                    // If current model is in list, select it
                    if availableModels.contains(where: { $0.id == selectedModel }) {
                        // Already selected
                    } else if let firstModel = availableModels.first {
                        selectedModel = firstModel.id
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingModels = false
                    saveStatus = "Failed to load models: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        saveStatus = ""
                    }
                }
            }
        }
    }

    private func saveSettings() {
        let settings = SettingsManager.shared
        settings.openRouterAPIKey = apiKey.isEmpty ? nil : apiKey
        settings.selectedModel = useCustomModel ? customModel : selectedModel
        settings.systemPrompt = systemPrompt
        settings.temperature = temperature

        saveStatus = "Settings saved successfully!"

        // Close window after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SettingsWindowController.shared.close()
        }
    }

    private func resetToDefaults() {
        selectedModel = "x-ai/grok-4.1-fast"
        customModel = "x-ai/grok-4.1-fast"
        systemPrompt =
            "You are a helpful writing assistant. Rewrite the user's text to be clear, concise, and well-written. Maintain the original meaning and tone."
        temperature = 0.7
        useCustomModel = false
    }
}

/// Window controller for settings
class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 650),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ProIME Settings"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView())

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func close() {
        window?.close()
    }
}
