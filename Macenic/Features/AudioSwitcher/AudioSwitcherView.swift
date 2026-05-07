import SwiftUI
import CoreAudio

struct AudioSwitcherView: View {
    let service: AudioService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                deviceSection(
                    title: "Output",
                    icon: "speaker.wave.2",
                    devices: service.outputDevices,
                    activeID: service.defaultOutputID,
                    onSelect: { service.setDefaultOutput($0) }
                )

                if !service.inputDevices.isEmpty {
                    Divider()
                        .padding(.horizontal, 12)

                    deviceSection(
                        title: "Input",
                        icon: "mic",
                        devices: service.inputDevices,
                        activeID: service.defaultInputID,
                        onSelect: { service.setDefaultInput($0) }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 380)
        .onAppear { service.refresh() }
    }

    private func deviceSection(
        title: String,
        icon: String,
        devices: [AudioDevice],
        activeID: AudioDeviceID,
        onSelect: @escaping (AudioDeviceID) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            ForEach(devices) { device in
                Button {
                    onSelect(device.id)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: device.id == activeID ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundStyle(device.id == activeID ? .blue : .secondary)
                        Text(device.name)
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
