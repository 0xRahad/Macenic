import SwiftUI

enum DashboardTab: String, CaseIterable {
    case system = "System"
    case clipboard = "Clipboard"
    case audio = "Audio"
    case toggles = "Toggles"
}

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: DashboardTab = .system

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            tabPicker
            Divider()
            tabContent
            Divider()
            footer
        }
        .frame(width: 340)
        .alert(
            "Version \(appState.updates.latestVersion) available",
            isPresented: updateAlertPresented
        ) {
            Button("Download") {
                appState.updates.openDownload()
            }
            Button("Later", role: .cancel) {
                appState.updates.dismissUpdate()
            }
        } message: {
            Text(updateMessage)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Macenic")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text("v1.0")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(DashboardTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .system:
            SystemMonitorView(monitor: appState.systemMonitor)
                .padding(.horizontal, 12)
        case .clipboard:
            ClipboardHistoryView(service: appState.clipboard, hotKey: appState.hotKey)
        case .audio:
            AudioSwitcherView(service: appState.audio)
        case .toggles:
            QuickTogglesView(
                keepAwake: appState.keepAwake,
                keyboardCleaner: appState.keyboardCleaner
            )
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                showAboutWindow()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("About")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button {
                Task { await appState.updates.checkForUpdates() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                    Text("Check Updates")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private static weak var aboutWindow: NSWindow?

    private var updateAlertPresented: Binding<Bool> {
        Binding(
            get: { appState.updates.isUpdateAvailable },
            set: { newValue in
                if !newValue {
                    appState.updates.dismissUpdate()
                }
            }
        )
    }

    private var updateMessage: String {
        if appState.updates.releaseNotes.isEmpty {
            return """
            • Bug fixes
            • Faster performance
            • UI improvements
            """
        }

        let lines = appState.updates.releaseNotes
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .map { line in
                if line.hasPrefix("-") || line.hasPrefix("*") || line.hasPrefix("•") {
                    return "• " + line.dropFirst().trimmingCharacters(in: .whitespaces)
                }
                return "• " + line
            }

        return lines.joined(separator: "\n")
    }

    private func showAboutWindow() {
        if let existing = Self.aboutWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let aboutView = AboutView()
        let hostingView = NSHostingView(rootView: aboutView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 280, height: 420)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        Self.aboutWindow = window
    }
}
