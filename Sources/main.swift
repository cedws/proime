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
    // Keep strong reference to prevent deallocation
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up standard Edit menu for copy/paste/select all shortcuts
        setupEditMenu()

        // Create menu bar item with SF Symbol that adapts to dark/light mode
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

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
        menu.delegate = self

        let settingsItem = NSMenuItem(
            title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Provider info
        let providerItem = NSMenuItem(
            title: "Provider: \(SettingsManager.shared.selectedProvider.displayName)",
            action: nil, keyEquivalent: "")
        providerItem.isEnabled = false
        providerItem.tag = 100  // Tag for updating
        menu.addItem(providerItem)

        // Status info
        let statusInfo = NSMenuItem(
            title: SettingsManager.shared.isConfigured ? "✓ Configured" : "⚠️ Not Configured",
            action: nil, keyEquivalent: "")
        statusInfo.isEnabled = false
        statusInfo.tag = 101  // Tag for updating
        menu.addItem(statusInfo)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit ProIME", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func setupEditMenu() {
        let mainMenu = NSMenu()

        // Edit menu for standard shortcuts
        let editMenu = NSMenu(title: "Edit")

        let undoItem = NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(undoItem)

        let redoItem = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(redoItem)

        editMenu.addItem(NSMenuItem.separator())

        let cutItem = NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(cutItem)

        let copyItem = NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(copyItem)

        let pasteItem = NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(pasteItem)

        let deleteItem = NSMenuItem(title: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: "")
        editMenu.addItem(deleteItem)

        let selectAllItem = NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(selectAllItem)

        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu

        mainMenu.addItem(editMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Update provider info when menu opens
        if let providerItem = menu.item(withTag: 100) {
            providerItem.title = "Provider: \(SettingsManager.shared.selectedProvider.displayName)"
        }
        // Update status when menu opens
        if let statusItem = menu.item(withTag: 101) {
            statusItem.title = SettingsManager.shared.isConfigured ? "✓ Configured" : "⚠️ Not Configured"
        }
    }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate

// Create our IME controller - this initializes the IMKServer
let controller = IMEController()

// Pre-warm connection for faster first request
LLMProviderFactory.current.prewarmConnection()

// Run the application's event loop
// Input Methods stay running in the background
NSApplication.shared.run()
