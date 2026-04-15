import Foundation
import AppKit
import Observation

@Observable
class AppManager {
    var apps: [AppInfo] = []
    var searchText = ""

    var filteredApps: [AppInfo] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var hiddenCount: Int {
        apps.filter(\.menuBarHidden).count
    }

    func loadApps() {
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]

        var discovered: [String: AppInfo] = [:]

        for basePath in searchPaths {
            let baseURL = URL(fileURLWithPath: basePath)
            guard let enumerator = FileManager.default.enumerator(
                at: baseURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in enumerator {
                guard url.pathExtension == "app" else { continue }
                enumerator.skipDescendants()

                guard let bundle = Bundle(url: url),
                      let bundleID = bundle.bundleIdentifier else { continue }
                if discovered[bundleID] != nil { continue }

                let name = bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? bundle.infoDictionary?["CFBundleName"] as? String
                    ?? url.deletingPathExtension().lastPathComponent

                discovered[bundleID] = AppInfo(
                    bundleIdentifier: bundleID,
                    name: name,
                    bundleURL: url,
                    menuBarHidden: readMenuBarHidden(for: bundleID)
                )
            }
        }

        apps = discovered.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func toggle(_ app: AppInfo) {
        guard let index = apps.firstIndex(where: { $0.id == app.id }) else { return }
        let newValue = !apps[index].menuBarHidden
        apps[index].menuBarHidden = newValue
        writeMenuBarHidden(newValue, for: app.bundleIdentifier)
    }

    // AppleMenuBarVisibleInFullscreen == false means the menu bar is hidden
    private func readMenuBarHidden(for bundleID: String) -> Bool {
        guard let defaults = UserDefaults(suiteName: bundleID),
              let value = defaults.object(forKey: "AppleMenuBarVisibleInFullscreen") as? Bool else {
            return false
        }
        return !value
    }

    private func writeMenuBarHidden(_ hidden: Bool, for bundleID: String) {
        guard let defaults = UserDefaults(suiteName: bundleID) else { return }
        if hidden {
            defaults.set(false, forKey: "AppleMenuBarVisibleInFullscreen")
        } else {
            defaults.removeObject(forKey: "AppleMenuBarVisibleInFullscreen")
        }
    }
}
