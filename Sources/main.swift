import Cocoa
import InputMethodKit

// Main entry point for the Input Method
// Input Methods run as background processes, not traditional apps with windows

// Bundle identifier must match Info.plist
let mainBundle = Bundle.main
let bundleIdentifier = mainBundle.bundleIdentifier!

NSLog("Starting Custom IME: \(bundleIdentifier)")

// Create our IME controller - this initializes the IMKServer
let controller = IMEController()

// Run the application's event loop
// Input Methods stay running in the background
NSApplication.shared.run()
