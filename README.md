# ProIME

macOS Input Method that uses AI to transform your text as you type. Works in any app.

## What It Does

Type text → Press Enter → AI rewrites it → Text gets inserted

Uses OpenRouter API for LLM access.

## Installation

```bash
# Install just if you don't have it
brew install just

# Build and install
just install
```

## Setup

1. Get API key from [openrouter.ai/keys](https://openrouter.ai/keys)
2. System Settings → Keyboard → Input Sources → Add "ProIME"
3. Click pencil icon in menu bar → Settings
4. Paste API key → Save

## Usage

1. Switch to ProIME (menu bar or Fn/Globe key)
2. Type your text (shows underlined)
3. Press **Enter** to transform
4. Press **Escape** to cancel
5. Press **Backspace** to edit

## Customization

Open Settings to change:
- **Model**: Default is `x-ai/grok-4.1-fast`
- **System Prompt**: Change how AI transforms text
- **Temperature**: 0.0-2.0 (lower = focused, higher = creative)

### Example System Prompts

**Grammar fix:**
```
Fix grammar and spelling. Output only the corrected text.
```

**Professional email:**
```
Make this a professional email. Output only the email.
```

**Expand notes:**
```
Expand these notes into a full paragraph. Output only the text.
```

## Build Commands

```bash
just          # Build
just install  # Build and install
just clean    # Clean build artifacts
just uninstall # Remove from system
```

## Requirements

- macOS 12.0+
- Xcode Command Line Tools
- Swift 5.9+
- just (`brew install just`)
- OpenRouter API key

## Troubleshooting

**"Not Configured" status**: Add API key in Settings

**IME not visible**: `killall TextInputMenuAgent` or log out/in

**Slow streaming**: Use faster model like `x-ai/grok-4.1-fast`

**Permissions**: System Settings → Privacy & Security → Accessibility

## License

MIT
