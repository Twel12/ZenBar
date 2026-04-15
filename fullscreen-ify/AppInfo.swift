import Foundation
import AppKit

struct AppInfo: Identifiable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let name: String
    let bundleURL: URL
    var menuBarHidden: Bool

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: bundleURL.path)
    }
}
