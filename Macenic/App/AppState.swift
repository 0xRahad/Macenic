import SwiftUI

private class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    var onDismiss: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onDismiss?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func resignKey() {
        super.resignKey()
        onDismiss?()
    }
}

@Observable
final class AppState {
    let systemMonitor = SystemMonitorService()
    let clipboard = ClipboardService()
    let audio = AudioService()
    let keepAwake = KeepAwakeService()
    let keyboardCleaner = KeyboardCleanerService()
    let hotKey = HotKeyService()

    @ObservationIgnored private var hudWindow: NSPanel?
    @ObservationIgnored private var escMonitor: Any?

    init() {
        systemMonitor.start()
        clipboard.start()
        audio.refresh()

        hotKey.onHotKey = { [weak self] in
            self?.toggleClipboardHUD()
        }
        hotKey.register()
    }

    func toggleClipboardHUD() {
        if let window = hudWindow, window.isVisible {
            hideClipboardHUD()
        } else {
            showClipboardHUD()
        }
    }

    func showClipboardHUD() {
        if hudWindow == nil {
            let hudView = ClipboardHUDView(
                service: clipboard,
                onPaste: { [weak self] item in
                    self?.clipboard.copyToClipboard(item)
                    self?.hideClipboardHUD()
                },
                onDismiss: { [weak self] in
                    self?.hideClipboardHUD()
                }
            )

            let contentRect = NSRect(x: 0, y: 0, width: 320, height: 400)

            let panel = FloatingPanel(
                contentRect: contentRect,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )

            let clearView = hudView.background(.clear)
            let hostingView = NSHostingView(rootView: clearView)
            hostingView.frame = contentRect
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = .clear

            if #available(macOS 26.0, *) {
                let glassView = NSGlassEffectView()
                glassView.frame = contentRect
                glassView.cornerRadius = 16
                glassView.contentView = hostingView
                panel.contentView = glassView
            } else {
                hostingView.layer?.cornerRadius = 16
                hostingView.layer?.masksToBounds = true
                panel.contentView = hostingView
            }

            panel.isFloatingPanel = true
            panel.level = .floating
            panel.isMovableByWindowBackground = true
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hidesOnDeactivate = false
            panel.becomesKeyOnlyIfNeeded = false
            panel.hasShadow = false
            panel.onDismiss = { [weak self] in
                self?.hideClipboardHUD()
            }

            hudWindow = panel
        }

        guard let panel = hudWindow, let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - panel.frame.width / 2
        let y = screenFrame.midY - panel.frame.height / 2
        panel.setFrameOrigin(NSPoint(x: x, y: y))

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if escMonitor == nil {
            escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == 53 {
                    self?.hideClipboardHUD()
                    return nil
                }
                return event
            }
        }
    }

    func hideClipboardHUD() {
        hudWindow?.orderOut(nil)
        if let monitor = escMonitor {
            NSEvent.removeMonitor(monitor)
            escMonitor = nil
        }
    }
}
