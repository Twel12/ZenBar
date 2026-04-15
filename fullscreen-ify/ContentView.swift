import SwiftUI

struct ContentView: View {
    @State private var manager = AppManager()

    var body: some View {
        NavigationStack {
            List(manager.filteredApps) { app in
                AppRow(app: app) {
                    manager.toggle(app)
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
            .navigationTitle("Fullscreen-ify")
            .toolbar {
                ToolbarItem {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("\(manager.hiddenCount)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .help("\(manager.hiddenCount) app(s) with menu bar hidden in fullscreen")
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
    let onToggle: () -> Void

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

            Toggle("Hide Menu Bar", isOn: Binding(
                get: { app.menuBarHidden },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .help("Hide the menu bar when this app enters fullscreen")
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}
