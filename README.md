# ProIME

macOS Input Method that uses AI to transform your text as you type. Works in any app.

## What It Does

Type text → Press Enter → AI rewrites it → Text gets inserted

Uses OpenRouter API for LLM access.

## Installation

### From Release (Recommended)

1. Download the latest `.zip` from the [Releases](https://github.com/cedws/proime/releases) page
2. Double-click the zip to extract `ProIME.app`
3. Double-click `ProIME.app` — macOS will block it
4. Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**
5. Copy `ProIME.app` to the Input Methods directory:
   ```bash
   cp -r ProIME.app ~/Library/Input\ Methods/
   ```
6. Log out and log back in
7. Go to **System Settings → Keyboard → Input Sources → Edit**, click **+**, and add **ProIME**
8. Press the **Fn** key to switch to ProIME — a pen icon will appear in the menu bar

### From Source

```bash
just install
```

## Setup

1. Get an API key from [OpenRouter](https://openrouter.ai/keys) or [GitHub Models](https://github.com/marketplace/models)
2. Click the pen icon in the menu bar → **Settings**
3. Paste your API key → **Save**

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
