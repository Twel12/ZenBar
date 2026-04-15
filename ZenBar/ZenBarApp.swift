import SwiftUI
import AppKit

@main
struct ZenBarApp: App {
    init() {
        if let appIcon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = appIcon
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 480, minHeight: 400)
        }
        .defaultSize(width: 560, height: 680)
    }
}
