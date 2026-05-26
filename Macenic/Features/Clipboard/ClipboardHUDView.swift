import SwiftUI

struct ClipboardHUDView: View {
    @Bindable var service: ClipboardService
    var onPaste: (ClipboardItem) -> Void
    var onDismiss: () -> Void

    @State private var selectedIndex: Int = 0
    @State private var hoveredItem: ClipboardItem?
    @State private var hoverTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            filterBar
            Divider()

            if service.filteredItems.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
        .frame(width: 320, height: 400)
        .onKeyPress(.return) {
            pasteSelected()
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveSelection(-1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(1)
            return .handled
        }
        .onKeyPress(characters: .decimalDigits) { press in
            guard let digit = Int(press.characters), digit >= 1, digit <= 9 else {
                return .ignored
            }
            let index = digit - 1
            guard index < service.filteredItems.count else { return .ignored }
            if press.modifiers.contains(.option) {
                onPaste(service.filteredItems[index])
            } else {
                selectedIndex = index
            }
            return .handled
        }
        .onChange(of: service.filteredItems.count) {
            selectedIndex = 0
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "clipboard")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Clipboard")
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            Text("ESC to close")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Picker("", selection: $service.selectedFilter) {
                ForEach(ClipboardFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var itemsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(Array(service.filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemRow(
                            item: item,
                            index: index,
                            isSelected: index == selectedIndex,
                            onTap: {
                                selectedIndex = index
                                hoverTask?.cancel()
                                hoveredItem = item
                            },
                            onPin: { service.togglePin(item) },
                            onDelete: { service.delete(item) }
                        )
                        .onHover { hovering in
                            hoverTask?.cancel()
                            if hovering {
                                hoverTask = Task {
                                    try? await Task.sleep(for: .milliseconds(300))
                                    guard !Task.isCancelled else { return }
                                    hoveredItem = item
                                }
                            } else {
                                hoverTask = Task {
                                    try? await Task.sleep(for: .milliseconds(120))
                                    guard !Task.isCancelled else { return }
                                    if hoveredItem?.id == item.id {
                                        hoveredItem = nil
                                    }
                                }
                            }
                        }
                        .popover(isPresented: Binding(
                            get: { hoveredItem?.id == item.id },
                            set: { if !$0 { hoveredItem = nil } }
                        ), arrowEdge: .trailing) {
                            HoverPreview(item: item)
                            .onHover { hovering in
                                if hovering {
                                    hoverTask?.cancel()
                                    hoveredItem = item
                                } else {
                                    hoverTask?.cancel()
                                    hoverTask = Task {
                                        try? await Task.sleep(for: .milliseconds(120))
                                        guard !Task.isCancelled else { return }
                                        if hoveredItem?.id == item.id {
                                            hoveredItem = nil
                                        }
                                    }
                                }
                            }
                        }
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
            .onChange(of: selectedIndex) { _, newValue in
                guard newValue < service.filteredItems.count else { return }
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo(service.filteredItems[newValue].id, anchor: .center)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Image(systemName: "clipboard")
                .font(.system(size: 24))
                .foregroundStyle(.quaternary)
            Text(service.searchQuery.isEmpty ? "No items" : "No matches")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func moveSelection(_ delta: Int) {
        let count = service.filteredItems.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + delta))
    }

    private func pasteSelected() {
        guard selectedIndex < service.filteredItems.count else { return }
        onPaste(service.filteredItems[selectedIndex])
    }
}

private struct HoverPreview: View {
    let item: ClipboardItem

    var body: some View {
        Group {
            switch item.content {
            case .text(let string):
                ScrollView {
                    Text(string)
                        .font(.system(size: 11))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
            case .image(let image):
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(10)
            }
        }
        .frame(width: 260, height: 300)
    }
}
