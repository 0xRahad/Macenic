import Carbon.HIToolbox
import AppKit

private func hotKeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return OSStatus(eventNotHandledErr) }
    let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        service.onHotKey?()
    }
    return noErr
}

struct KeyShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultClipboard = KeyShortcut(keyCode: 9, modifiers: 0x0300)

    private static let keyNames: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
        24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
        32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K",
        43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        49: "Space", 96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
        101: "F9", 103: "F11", 109: "F10", 111: "F12", 118: "F4",
        120: "F2", 122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑"
    ]

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(Self.keyNames[keyCode] ?? "?")
        return parts.joined()
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }
}

@Observable
final class HotKeyService {
    var onHotKey: (() -> Void)?
    var currentShortcut: KeyShortcut = .defaultClipboard
    var isRecording = false

    @ObservationIgnored private var hotKeyRef: EventHotKeyRef?
    @ObservationIgnored private var handlerRef: EventHandlerRef?
    @ObservationIgnored private var recordMonitor: Any?

    private static let shortcutKey = "clipboardShortcut"

    init() {
        loadShortcut()
    }

    func register() {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            selfPtr,
            &handlerRef
        )

        var hotKeyID = EventHotKeyID(signature: 0x4D434E43, id: 1)

        RegisterEventHotKey(
            currentShortcut.keyCode,
            currentShortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
    }

    func startRecording() {
        unregister()
        isRecording = true
        recordMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let mods = KeyShortcut.carbonModifiers(from: event.modifierFlags)
            guard mods != 0 else { return nil }
            let newShortcut = KeyShortcut(keyCode: UInt32(event.keyCode), modifiers: mods)
            self.currentShortcut = newShortcut
            self.saveShortcut()
            self.stopRecording()
            self.register()
            return nil
        }
    }

    func stopRecording() {
        isRecording = false
        if let monitor = recordMonitor {
            NSEvent.removeMonitor(monitor)
            recordMonitor = nil
        }
    }

    func cancelRecording() {
        stopRecording()
        register()
    }

    private func saveShortcut() {
        if let data = try? JSONEncoder().encode(currentShortcut) {
            UserDefaults.standard.set(data, forKey: Self.shortcutKey)
        }
    }

    private func loadShortcut() {
        guard let data = UserDefaults.standard.data(forKey: Self.shortcutKey),
              let shortcut = try? JSONDecoder().decode(KeyShortcut.self, from: data)
        else { return }
        currentShortcut = shortcut
    }
}
