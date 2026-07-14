import Foundation
import AppKit
import Observation

@Observable
class AppManager {
    private let fullscreenKey = "AppleMenuBarVisibleInFullscreen"
    private let workerQueue = DispatchQueue(label: "AppManager.worker", qos: .userInitiated)

    var apps: [AppInfo] = []
    var searchText = ""

    var filteredApps: [AppInfo] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var overriddenCount: Int {
        apps.filter { $0.menuBarMode != .stock }.count
    }

    func loadApps() {
        workerQueue.async { [weak self] in
            guard let self else { return }

            let overrides = self.readOverridesFromDefaultsFind()
            var discovered: [String: AppInfo] = [:]

            for appURL in self.discoverAppURLs() {
                guard let bundle = Bundle(url: appURL),
                      let bundleID = bundle.bundleIdentifier,
                      discovered[bundleID] == nil else { continue }

                let appName = self.readAppName(from: appURL, bundleID: bundleID)
                discovered[bundleID] = AppInfo(
                    bundleIdentifier: bundleID,
                    name: appName,
                    bundleURL: appURL,
                    icon: NSWorkspace.shared.icon(forFile: appURL.path),
                    menuBarMode: overrides[bundleID] ?? .stock
                )
            }

            let sortedApps = discovered.values.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            DispatchQueue.main.async { [weak self] in
                self?.apps = sortedApps
            }
        }
    }

    func setMenuBarMode(_ mode: FullscreenMenuBarMode, for app: AppInfo) {
        guard let index = apps.firstIndex(where: { $0.id == app.id }) else { return }

        let result: (status: Int32, output: String, error: String)
        switch mode {
        case .stock:
            result = runDefaults("delete", app.bundleIdentifier, fullscreenKey, logFailures: false)
        case .forceHide:
            result = runDefaults("write", app.bundleIdentifier, fullscreenKey, "-bool", "false")
        case .forceShow:
            result = runDefaults("write", app.bundleIdentifier, fullscreenKey, "-bool", "true")
        }

        let isSuccessfulWrite = result.status == 0 || (mode == .stock && result.status == 1)
        if isSuccessfulWrite {
            apps[index].menuBarMode = mode
        }
    }

    private func discoverAppURLs() -> [URL] {
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: NSHomeDirectory() + "/Applications")
        ]

        var appURLs: [URL] = []
        let fileManager = FileManager.default

        for root in roots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in enumerator {
                guard url.pathExtension == "app" else { continue }
                appURLs.append(url)
                enumerator.skipDescendants()
            }
        }

        return appURLs
    }

    private func readAppName(from appURL: URL, bundleID: String) -> String {
        if let bundle = Bundle(url: appURL) {
            return bundle.infoDictionary?["CFBundleDisplayName"] as? String
                ?? bundle.infoDictionary?["CFBundleName"] as? String
                ?? appURL.deletingPathExtension().lastPathComponent
        }
        return appURL.deletingPathExtension().lastPathComponent.isEmpty
            ? bundleID
            : appURL.deletingPathExtension().lastPathComponent
    }

    private func readOverridesFromDefaultsFind() -> [String: FullscreenMenuBarMode] {
        let result = runDefaults("find", fullscreenKey, logFailures: false)
        guard result.status == 0 else { return [:] }

        var overrides: [String: FullscreenMenuBarMode] = [:]
        var currentDomain: String?

        for line in result.output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("Found"),
               let openQuote = trimmed.firstIndex(of: "'"),
               let closeQuote = trimmed[trimmed.index(after: openQuote)...].firstIndex(of: "'") {
                currentDomain = String(trimmed[trimmed.index(after: openQuote)..<closeQuote])
                continue
            }

            guard let domain = currentDomain,
                  trimmed.hasPrefix(fullscreenKey) else { continue }

            if trimmed.contains("= 0") || trimmed.contains("= false") {
                overrides[domain] = .forceHide
            } else if trimmed.contains("= 1") || trimmed.contains("= true") {
                overrides[domain] = .forceShow
            }

            currentDomain = nil
        }

        return overrides
    }

    @discardableResult
    private func runDefaults(_ arguments: String..., logFailures: Bool = true) -> (status: Int32, output: String, error: String) {
        let result = runCommand(executable: "/usr/bin/defaults", arguments: arguments)
        _ = logFailures // preserve call sites, no verbose logging in normal usage
        return result
    }

    private func runCommand(executable: String, arguments: [String]) -> (status: Int32, output: String, error: String) {
        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (-1, "", "\(error)")
        }

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

        let out = String(data: outData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let err = String(data: errData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return (process.terminationStatus, out, err)
    }
}
