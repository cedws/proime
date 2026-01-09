# Custom macOS Input Method (IME) - Text Transformer

A macOS Input Method that globally transforms text as users type across all applications.

## Architecture Overview

### Key Components

1. **IMEController.swift** - Manages the IMKServer lifecycle
   - Initializes the Input Method server
   - Handles connection management
   - Acts as the principal class

2. **InputController.swift** - Handles text input and transformation
   - Intercepts keystrokes via `handle(_:client:)` method
   - Transforms text in real-time
   - Manages composition (the underlined text shown while typing)
   - Commits transformed text to applications

3. **main.swift** - Entry point
   - Creates the IME controller
   - Runs the application event loop

4. **Info.plist** - Configuration
   - Registers the app as an Input Method
   - Defines connection names and class names
   - Sets up menu display information

## How It Works

### Text Flow

1. User types a character in **any app** (while IME is selected)
2. macOS routes the keystroke to our IME via `handle(_:client:)`
3. The character is added to `composedBuffer`
4. `transformText()` applies the transformation
5. Transformed text is shown as **marked text** (underlined)
6. User presses Enter → text is **committed** to the app
7. User presses Escape → composition is **cancelled**
8. User presses Backspace → removes last character from buffer

### Text Transformations

The example includes several transformation functions:

- **Leetspeak**: Converts letters to numbers (a→4, e→3, i→1, etc.)
- **ROT13**: Caesar cipher rotation
- **Uppercase**: Simple case conversion

You can implement any transformation logic in `transformText()`:

```swift
private func transformText(_ input: String) -> String {
    // Your transformation here
    return input.uppercased()
}
```

## Building the Input Method

This project uses **Swift Package Manager** with a Makefile for easy building and installation.

### Quick Start

```bash
# Build universal binary (arm64 + x86_64)
make

# Build and install
make install

# Clean build artifacts
make clean

# Uninstall from system
make uninstall

# Show all commands
make help
```

### Build System

The project includes:
- **Package.swift** - Swift Package Manager configuration
- **Makefile** - Build automation with universal binary support
- **Sources/** - Swift source code
- **Resources/** - Info.plist, icons, and localizations

### Build Targets

- `make` or `make universal` - Creates a universal binary supporting both Apple Silicon (arm64) and Intel (x86_64)
- `make install` - Builds and installs to `~/Library/Input Methods/`
- `make clean` - Removes all build artifacts
- `make uninstall` - Removes the app from the system

### Manual Build (Advanced)

If you prefer to use Swift Package Manager directly:

```bash
# Build for your architecture
swift build -c release

# Build for specific architecture
swift build -c release --arch arm64
swift build -c release --arch x86_64
```

Note: The Makefile handles universal binary creation automatically using `lipo`.

### Requirements

- **macOS 11.0+** (Big Sur or later)
- **Xcode Command Line Tools** (for Swift compiler)
- **Swift 5.9+**

## Installation

### Automatic Installation (Recommended)

```bash
make install
```

This will:
1. Build a universal binary
2. Stop any running instances
3. Install to `~/Library/Input Methods/`
4. Restart the input menu agent

### Manual Installation

1. Build the app: `make`
2. Copy `build/CustomTextTransformer.app` to:
   - `~/Library/Input Methods/` (current user only)
   - `/Library/Input Methods/` (system-wide, requires admin)

3. Restart the input menu: `killall TextInputMenuAgent`

### Enabling the Input Method

1. Go to **System Settings** → **Keyboard** → **Input Sources**
2. Click the **+** button
3. Find "Text Transformer" in the list
4. Add it
5. Switch to it using the input menu in the menu bar or press Fn/Globe key

### Troubleshooting

**IME doesn't appear in Input Sources:**
- Check Info.plist configuration
- Ensure bundle identifier matches everywhere
- Verify app is in correct Input Methods folder
- Try restarting the Mac

**IME doesn't intercept keystrokes:**
- Grant Accessibility permissions in System Settings → Privacy & Security
- Check Console.app for error messages
- Verify `InputMethodConnectionName` matches between Info.plist and IMEController.swift

**IME crashes or doesn't respond:**
- Check Console.app logs
- Add NSLog statements for debugging
- Ensure proper nil checking in InputController methods

## Customization Examples

### Example 1: Auto-correct Common Typos

```swift
private func transformText(_ input: String) -> String {
    let corrections: [String: String] = [
        "teh": "the",
        "recieve": "receive",
        "seperate": "separate"
    ]
    
    var result = input
    for (typo, correction) in corrections {
        result = result.replacingOccurrences(of: typo, with: correction)
    }
    return result
}
```

### Example 2: Text Expansion

```swift
private func transformText(_ input: String) -> String {
    let expansions: [String: String] = [
        "@@": "your.email@example.com",
        "addr": "123 Main Street, City, State 12345",
        "shrug": "¯\\_(ツ)_/¯"
    ]
    
    return expansions[input] ?? input
}
```

### Example 3: Emoji Substitution

```swift
private func transformText(_ input: String) -> String {
    return input
        .replacingOccurrences(of: ":)", with: "😊")
        .replacingOccurrences(of: ":(", with: "😢")
        .replacingOccurrences(of: ":D", with: "😄")
        .replacingOccurrences(of: "<3", with: "❤️")
}
```

### Example 4: Case Transformation with Prefix

```swift
private func transformText(_ input: String) -> String {
    if input.hasPrefix(">>") {
        // Remove prefix and uppercase everything after
        return String(input.dropFirst(2)).uppercased()
    }
    return input
}
```

## Advanced Features

### Real-time Transformation (No Buffer)

For instant character-by-character transformation without waiting for Enter:

```swift
private func handleCharacterInput(_ characters: String, client sender: Any!) -> Bool {
    let transformed = transformText(characters)
    
    // Commit immediately instead of showing marked text
    guard let client = sender as? IMKTextInput else { return false }
    client.insertText(transformed, 
                    replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
    
    return true
}
```

### Context-Aware Transformations

Access the text before the cursor for smarter transformations:

```swift
override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
    guard let client = sender as? IMKTextInput else { return false }
    
    // Get text before cursor
    if let precedingText = client.string(
        from: NSRange(location: 0, length: NSNotFound),
        actualRange: nil
    ) {
        NSLog("Context: \(precedingText)")
        // Use context to make transformation decisions
    }
    
    // ... rest of handling
}
```

## Security & Privacy

- Input Methods have access to **all keystrokes** in all apps
- They can read and modify text in any application
- macOS requires user consent via Accessibility permissions
- Always handle user data responsibly
- Consider encryption for any data storage
- Be transparent about what transformations are applied

## Limitations

- Cannot intercept secure text fields (passwords)
- Some apps may not support Input Methods fully
- Requires restart/re-login after installation
- Must be code-signed for distribution
- Cannot run in App Sandbox

## Distribution

For public distribution:

1. Sign with Developer ID
2. Notarize with Apple
3. Provide installer that copies to `/Library/Input Methods/`
4. Include instructions for enabling in System Settings

## References

- Apple Documentation: [Input Method Kit](https://developer.apple.com/documentation/inputmethodkit)
- Technical Note TN2179: Input Method Kit
- Sample Code: NumberInput IME (Apple's example)
