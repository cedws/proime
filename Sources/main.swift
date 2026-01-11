import Cocoa
import InputMethodKit

// Main entry point for the Input Method
// Input Methods run as background processes, not traditional apps with windows

// Bundle identifier must match Info.plist
let mainBundle = Bundle.main
guard let bundleIdentifier = mainBundle.bundleIdentifier else {
    fatalError("Bundle identifier not found in Info.plist")
}

NSLog("Starting Custom IME: \(bundleIdentifier)")

// Set up app delegate to handle menu
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item with SF Symbol that adapts to dark/light mode
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Use SF Symbol for native look
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            let image = NSImage(
                systemSymbolName: "pencil.line", accessibilityDescription: "ProIME")
            image?.isTemplate = true  // This makes it adapt to light/dark mode

            if let configuredImage = image?.withSymbolConfiguration(config) {
                button.image = configuredImage
            } else {
                button.image = image
            }
        }

        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let statusInfo = NSMenuItem(
            title: SettingsManager.shared.isConfigured ? "✓ Configured" : "⚠️ Not Configured",
            action: nil, keyEquivalent: "")
        statusInfo.isEnabled = false
        menu.addItem(statusInfo)

        statusItem.menu = menu
    }

    @objc func openSettings() {
        SettingsWindowController.shared.show()
    }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate

// Create our IME controller - this initializes the IMKServer
let controller = IMEController()

// Pre-warm OpenRouter connection for faster first request
OpenRouterClient.shared.prewarmConnection()

// Run the application's event loop
// Input Methods stay running in the background
NSApplication.shared.run()
