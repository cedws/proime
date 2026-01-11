import Cocoa
import InputMethodKit

/// Main controller for the Input Method
/// This class handles the lifecycle and manages the IMKServer instance
@objc(IMEController)
class IMEController: NSObject {
    var server: IMKServer!

    override init() {
        super.init()

        // Initialize the IMKServer using bundle identifier approach
        // This matches the pattern from working GitHub examples
        // The InputMethodConnectionName from Info.plist is used for the connection
        let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String

        server = IMKServer(
            name: connectionName,
            bundleIdentifier: Bundle.main.bundleIdentifier)

        NSLog("ProIME Server initialized")
        NSLog("Connection name: \(connectionName ?? "nil")")
        NSLog("Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
    }
}
