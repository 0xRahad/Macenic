import CoreAudio
import Foundation

@Observable
final class AudioService {
    var outputDevices: [AudioDevice] = []
    var inputDevices: [AudioDevice] = []
    var defaultOutputID: AudioDeviceID = 0
    var defaultInputID: AudioDeviceID = 0

    func refresh() {
        loadDevices()
        loadDefaults()
    }

    func setDefaultOutput(_ deviceID: AudioDeviceID) {
        setDefault(deviceID, selector: kAudioHardwarePropertyDefaultOutputDevice)
        defaultOutputID = deviceID
    }

    func setDefaultInput(_ deviceID: AudioDeviceID) {
        setDefault(deviceID, selector: kAudioHardwarePropertyDefaultInputDevice)
        defaultInputID = deviceID
    }

    private func setDefault(_ deviceID: AudioDeviceID, selector: AudioObjectPropertySelector) {
        var id = deviceID
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil,
            UInt32(MemoryLayout<AudioDeviceID>.size), &id
        )
    }

    private func loadDevices() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &dataSize
        ) == noErr else { return }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)

        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &dataSize, &ids
        ) == noErr else { return }

        var outputs: [AudioDevice] = []
        var inputs: [AudioDevice] = []

        for id in ids {
            guard let name = deviceName(id) else { continue }
            let hasOut = hasStreams(id, scope: kAudioDevicePropertyScopeOutput)
            let hasIn = hasStreams(id, scope: kAudioDevicePropertyScopeInput)
            let device = AudioDevice(id: id, name: name, hasInput: hasIn, hasOutput: hasOut)
            if hasOut { outputs.append(device) }
            if hasIn { inputs.append(device) }
        }

        outputDevices = outputs
        inputDevices = inputs
    }

    private func loadDefaults() {
        defaultOutputID = getDefault(kAudioHardwarePropertyDefaultOutputDevice)
        defaultInputID = getDefault(kAudioHardwarePropertyDefaultInputDevice)
    }

    private func getDefault(_ selector: AudioObjectPropertySelector) -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        return deviceID
    }

    private func deviceName(_ deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        guard AudioObjectGetPropertyData(
            deviceID, &address, 0, nil, &size, &name
        ) == noErr else { return nil }
        return name as String
    }

    private func hasStreams(_ deviceID: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            deviceID, &address, 0, nil, &size
        ) == noErr else { return false }
        return size > 0
    }
}
