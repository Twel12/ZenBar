import SwiftUI

struct ContentView: View {
    @State private var manager = AppManager()

    var body: some View {
        NavigationStack {
            List(manager.filteredApps) { app in
                AppRow(app: app) { mode in
                    manager.setMenuBarMode(mode, for: app)
                }
            }
            .overlay {
                if manager.filteredApps.isEmpty {
                    if manager.searchText.isEmpty {
                        ContentUnavailableView(
                            "No Apps Found",
                            systemImage: "app.dashed",
                            description: Text("Could not discover any applications.")
                        )
                    } else {
                        ContentUnavailableView.search(text: manager.searchText)
                    }
                }
            }
            .searchable(text: $manager.searchText, prompt: "Search apps...")
            .navigationTitle("ZenBar")
            .toolbar {
                ToolbarItem {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.secondary)
                        Text("\(manager.overriddenCount)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .help("\(manager.overriddenCount) app(s) overriding stock behavior")
                }
                ToolbarItem {
                    Button(action: { manager.loadApps() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .help("Rescan installed applications")
                }
            }
        }
        .onAppear { manager.loadApps() }
    }
}

struct AppRow: View {
    let app: AppInfo
    let onModeChange: (FullscreenMenuBarMode) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .fontWeight(.medium)
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Picker("Fullscreen Menu Bar", selection: Binding(
                get: { app.menuBarMode },
                set: { newMode in onModeChange(newMode) }
            )) {
                ForEach(FullscreenMenuBarMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120, alignment: .trailing)
            .fixedSize(horizontal: true, vertical: false)
            .labelsHidden()
            .help("Choose stock behavior, force hide, or force show in fullscreen")
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}
