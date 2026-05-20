import SwiftUI

@main
struct PulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var metrics = MetricsService()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(metrics)
        } label: {
            Text(metrics.menuBarText)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(metrics.healthTint)
        }
        .menuBarExtraStyle(.window)
    }
}
