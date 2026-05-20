import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Keep the app out of the Dock and Command-Tab switcher.
        NSApp.setActivationPolicy(.accessory)
    }
}
