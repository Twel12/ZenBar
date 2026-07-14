import Foundation
import AppKit

enum FullscreenMenuBarMode: String, CaseIterable, Identifiable {
    case stock
    case forceHide
    case forceShow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stock:
            return "Stock"
        case .forceHide:
            return "Force Hide"
        case .forceShow:
            return "Force Show"
        }
    }
}

struct AppInfo: Identifiable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let name: String
    let bundleURL: URL
    let icon: NSImage
    var menuBarMode: FullscreenMenuBarMode
}
