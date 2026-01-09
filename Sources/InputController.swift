import Cocoa
import InputMethodKit

/// The main input controller that handles keystroke events
/// This is where text transformation happens
@objc(InputController)
class InputController: IMKInputController {

    // Buffer to accumulate characters before committing
    private var composedBuffer = ""

    // MARK: - Initialization

    /// Required initializer for IMKInputController
    /// This is called by IMKServer when creating controller instances
    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
        NSLog("InputController initialized for client")
    }

    // MARK: - Text Input Handling

    /// Called when the user types a character
    /// Return true if we handle the event, false to pass through
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event = event else { return false }

        // Only handle key down events
        guard event.type == .keyDown else { return false }

        let keyCode = event.keyCode
        let characters = event.characters ?? ""

        NSLog("Key pressed: \(characters) (code: \(keyCode))")

        // Handle special keys
        switch keyCode {
        case 36:  // Return/Enter
            commitComposition(sender)
            return true

        case 51:  // Delete/Backspace
            handleBackspace(sender)
            return true

        case 53:  // Escape
            cancelComposition(sender)
            return true

        default:
            break
        }

        // Handle regular character input
        if !characters.isEmpty {
            return handleCharacterInput(characters, client: sender)
        }

        return false
    }

    /// Transform and handle character input
    private func handleCharacterInput(_ characters: String, client sender: Any!) -> Bool {
        // Add to our buffer
        composedBuffer += characters

        // Apply transformation
        let transformed = transformText(composedBuffer)

        // Update the marked text (underlined text showing transformation)
        updateMarkedText(transformed, client: sender)

        return true
    }

    /// This is where you define your text transformation logic
    /// Examples: ROT13, leetspeak, case changes, emoji replacement, etc.
    private func transformText(_ input: String) -> String {
        // Example 1: Convert to uppercase
        // return input.uppercased()

        // Example 2: ROT13 cipher
        // return rot13(input)

        // Example 3: Leetspeak transformation
        return applyLeetspeak(input)

        // Example 4: Simple character substitution
        // return input.replacingOccurrences(of: "a", with: "@")
        //            .replacingOccurrences(of: "e", with: "3")
    }

    /// Example transformation: Leetspeak
    private func applyLeetspeak(_ text: String) -> String {
        let substitutions: [Character: String] = [
            "a": "4", "A": "4",
            "e": "3", "E": "3",
            "i": "1", "I": "1",
            "o": "0", "O": "0",
            "s": "5", "S": "5",
            "t": "7", "T": "7",
            "l": "1", "L": "1",
        ]

        return text.map { char in
            substitutions[char] ?? String(char)
        }.joined()
    }

    /// Example transformation: ROT13
    private func rot13(_ text: String) -> String {
        return text.map { char in
            if let scalar = char.unicodeScalars.first {
                let value = scalar.value
                switch value {
                case 65...90:  // A-Z
                    return Character(UnicodeScalar((value - 65 + 13) % 26 + 65)!)
                case 97...122:  // a-z
                    return Character(UnicodeScalar((value - 97 + 13) % 26 + 97)!)
                default:
                    return char
                }
            }
            return char
        }.map(String.init).joined()
    }

    // MARK: - Composition Management

    /// Update the marked (underlined) text shown to user
    private func updateMarkedText(_ text: String, client sender: Any!) {
        guard let client = sender as? IMKTextInput else { return }

        // Create attributed string for the marked text
        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        let markedText = NSAttributedString(string: text, attributes: attributes)

        // Set the marked text in the client application
        client.setMarkedText(
            markedText,
            selectionRange: NSRange(location: text.count, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
    }

    /// Commit the transformed text to the application
    override func commitComposition(_ sender: Any!) {
        guard let client = sender as? IMKTextInput else { return }

        if !composedBuffer.isEmpty {
            let transformed = transformText(composedBuffer)

            // Insert the transformed text
            client.insertText(
                transformed,
                replacementRange: NSRange(location: NSNotFound, length: NSNotFound))

            NSLog("Committed: '\(composedBuffer)' -> '\(transformed)'")

            // Clear the buffer
            composedBuffer = ""
        }
    }

    /// Handle backspace key
    private func handleBackspace(_ sender: Any!) {
        guard let client = sender as? IMKTextInput else { return }

        if !composedBuffer.isEmpty {
            composedBuffer.removeLast()

            if composedBuffer.isEmpty {
                // Cancel composition if buffer is empty
                client.setMarkedText(
                    "",
                    selectionRange: NSRange(location: 0, length: 0),
                    replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
            } else {
                // Update with remaining text
                let transformed = transformText(composedBuffer)
                updateMarkedText(transformed, client: sender)
            }
        }
    }

    /// Cancel the current composition
    private func cancelComposition(_ sender: Any!) {
        guard let client = sender as? IMKTextInput else { return }

        composedBuffer = ""
        client.setMarkedText(
            "",
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
    }

    // MARK: - IMKInputController Overrides

    /// Called when input method is activated
    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        NSLog("IME activated")
        composedBuffer = ""
    }

    /// Called when input method is deactivated
    override func deactivateServer(_ sender: Any!) {
        commitComposition(sender)
        super.deactivateServer(sender)
        NSLog("IME deactivated")
    }

    /// Provide the menu for input method selection
    override func menu() -> NSMenu! {
        let menu = NSMenu(title: "Custom Text Transformer")

        let item = NSMenuItem(
            title: "Text Transformer IME",
            action: nil,
            keyEquivalent: "")
        menu.addItem(item)

        return menu
    }
}
