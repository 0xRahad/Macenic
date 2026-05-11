import SwiftUI

struct ClipboardHistoryView: View {
    @Bindable var service: ClipboardService
    var hotKey: HotKeyService? = nil

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterBar

            if service.filteredItems.isEmpty {
                emptyState
            } else {
                itemsList
            }

            if !service.items.isEmpty {
                Divider()
                bottomBar
            }
        }
        .frame(height: 440)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("Search clipboard...", text: $service.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Picker("", selection: $service.selectedFilter) {
                ForEach(ClipboardFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if let hotKey {
                Spacer()
                shortcutBadge(hotKey: hotKey)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private func shortcutBadge(hotKey: HotKeyService) -> some View {
        Button(action: {
            if hotKey.isRecording {
                hotKey.cancelRecording()
            } else {
                hotKey.startRecording()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                    .font(.system(size: 10))
                Text(hotKey.isRecording ? "Press keys..." : hotKey.currentShortcut.displayString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(hotKey.isRecording ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(hotKey.isRecording ? AnyShapeStyle(.tint.opacity(0.1)) : AnyShapeStyle(.quaternary))
            )
        }
        .buttonStyle(.plain)
        .help("Click to change shortcut")
    }

    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(service.filteredItems) { item in
                    ClipboardItemRow(
                        item: item,
                        onCopy: { service.copyToClipboard(item) },
                        onPin: { service.togglePin(item) },
                        onDelete: { service.delete(item) }
                    )
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Image(systemName: "clipboard")
                .font(.system(size: 24))
                .foregroundStyle(.quaternary)
            Text(service.searchQuery.isEmpty ? "Clipboard history is empty" : "No matches found")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var bottomBar: some View {
        HStack {
            Button(action: { service.clearUnpinned() }) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                    Text("Clear Unpinned")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            if let hotKey {
                Text(hotKey.currentShortcut.displayString)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
