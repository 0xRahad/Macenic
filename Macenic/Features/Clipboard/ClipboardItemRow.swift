import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    var index: Int? = nil
    var isSelected: Bool = false
    let onTap: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if let index, index < 9 {
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)
            }

            contentPreview
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onPin) {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 10))
                    .foregroundStyle(item.isPinned ? .orange : .secondary)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? AnyShapeStyle(.tint.opacity(0.15)) : AnyShapeStyle(.quaternary.opacity(0.5)))
        )
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.content {
        case .text(let string):
            Text(string)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
        case .image(let image):
            HStack(spacing: 6) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                if let dims = item.imageDimensions {
                    Text("\(Int(dims.width))×\(Int(dims.height))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
