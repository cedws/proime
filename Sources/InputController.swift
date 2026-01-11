import Cocoa
import InputMethodKit

/// Key code constants for special keys
private enum KeyCode {
    static let returnKey: UInt16 = 36
    static let backspace: UInt16 = 51
    static let escape: UInt16 = 53
}

/// Error message display configuration
private enum ErrorDisplayConfig {
    static let minimumDisplayTime: TimeInterval = 3.0
    static let charactersPerSecond: Double = 20.0
}

/// The main input controller that handles keystroke events
@objc(InputController)
class InputController: IMKInputController {
    private var composedBuffer = ""
    private var isStreaming = false
    private var llmResponse = ""

    // MARK: - Text Input Handling

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event = event, event.type == .keyDown else { return false }

        let keyCode = event.keyCode

        // Pass through Cmd shortcuts
        if event.modifierFlags.contains(.command) { return false }

        // Handle special keys
        switch keyCode {
        case KeyCode.returnKey:
            guard !isStreaming, !composedBuffer.isEmpty else { return isStreaming }
            startLLMTransformation(sender)
            return true

        case KeyCode.backspace:
            guard !composedBuffer.isEmpty, !isStreaming else { return false }
            handleBackspace(sender)
            return true

        case KeyCode.escape:
            if isStreaming {
                cancelStreaming(sender)
                return true
            } else if !composedBuffer.isEmpty {
                clearMarkedText(sender)
                composedBuffer = ""
                return true
            }
            return false

        default:
            guard !isStreaming, let characters = event.characters, !characters.isEmpty else {
                return isStreaming
            }
            composedBuffer += characters
            updateMarkedText(composedBuffer, client: sender)
            return true
        }
    }

    // MARK: - LLM Streaming

    private func startLLMTransformation(_ sender: Any!) {
        guard SettingsManager.shared.isConfigured else {
            showError("⚠️ Please configure OpenRouter API key in Settings", sender)
            return
        }

        // Capture client reference to prevent deallocation during streaming
        guard let client = sender as? IMKTextInput else { return }

        let inputText = composedBuffer
        isStreaming = true
        llmResponse = ""

        var firstTokenReceived = false

        OpenRouterClient.shared.streamCompletion(
            prompt: inputText,
            onToken: { [weak self] token in
                guard let self = self else { return }

                if !firstTokenReceived {
                    firstTokenReceived = true
                    self.composedBuffer = ""
                }

                self.llmResponse += token
                self.updateMarkedText(self.llmResponse, client: client)
            },
            onComplete: { [weak self] fullText in
                guard let self = self else { return }
                client.insertText(
                    fullText, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
                self.resetState()
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.showError("Error: \(error.localizedDescription)", client)
            }
        )
    }

    private func cancelStreaming(_ sender: Any!) {
        clearMarkedText(sender)
        resetState()
    }

    private func showError(_ message: String, _ sender: Any!) {
        updateMarkedText(message, client: sender)

        // Calculate display duration based on message length
        let displayDuration = max(
            ErrorDisplayConfig.minimumDisplayTime,
            Double(message.count) / ErrorDisplayConfig.charactersPerSecond
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [weak self] in
            self?.clearMarkedText(sender)
            self?.resetState()
        }
    }

    // MARK: - Helpers

    private func updateMarkedText(_ text: String, client sender: Any!) {
        guard let client = sender as? IMKTextInput, !text.isEmpty else { return }

        let markedText = NSAttributedString(
            string: text,
            attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue]
        )

        client.setMarkedText(
            markedText,
            selectionRange: NSRange(location: text.count, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    private func clearMarkedText(_ sender: Any!) {
        guard let client = sender as? IMKTextInput else { return }
        client.setMarkedText(
            "",
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    private func handleBackspace(_ sender: Any!) {
        composedBuffer.removeLast()
        if composedBuffer.isEmpty {
            clearMarkedText(sender)
        } else {
            updateMarkedText(composedBuffer, client: sender)
        }
    }

    private func resetState() {
        composedBuffer = ""
        llmResponse = ""
        isStreaming = false
    }

    // MARK: - IMKInputController Overrides

    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        resetState()
    }

    override func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
    }

    override func menu() -> NSMenu! {
        let menu = NSMenu(title: "ProIME")

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let statusItem = NSMenuItem(
            title: SettingsManager.shared.isConfigured ? "✓ Configured" : "⚠️ Not Configured",
            action: nil,
            keyEquivalent: ""
        )
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        return menu
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }
}
