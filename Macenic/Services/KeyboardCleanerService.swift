import AppKit
import SwiftUI
import CoreGraphics

private var activeEventTap: CFMachPort?

private func keyboardCleanerCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        if let tap = activeEventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    default:
        return nil
    }
}

private class CleanerWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    var onClickAnywhere: (() -> Void)?

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .keyDown, .keyUp, .flagsChanged:
            return
        case .leftMouseDown, .rightMouseDown:
            onClickAnywhere?()
        default:
            super.sendEvent(event)
        }
    }
}

@Observable
final class KeyboardCleanerService {
    var isActive = false
    var permissionDenied = false

    @ObservationIgnored private var cleanerWindow: NSWindow?
    @ObservationIgnored private var exitTimer: Timer?
    @ObservationIgnored private var runLoopSource: CFRunLoopSource?
    @ObservationIgnored private var permissionPollTimer: Timer?
    @ObservationIgnored private var pendingDuration: Int = 30

    static var hasPermission: Bool {
        AXIsProcessTrusted()
    }

    func activate(duration: Int = 30) {
        guard !isActive else { return }

        if !Self.hasPermission {
            permissionDenied = false
            pendingDuration = duration
            openAccessibilitySettings()
            return
        }

        permissionDenied = false
        stopPermissionPolling()
        startCleaner(duration: duration)
    }

    func openAccessibilitySettings() {
        stopPermissionPolling()
        triggerPermissionFlow()

        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ]

        var opened = false
        for string in urls {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                opened = true
                break
            }
        }

        if !opened {
            NSWorkspace.shared.open(
                URL(fileURLWithPath: "/System/Applications/System Settings.app")
            )
        }

        startPermissionPolling()
    }

    private func triggerPermissionFlow() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        startPermissionPolling()
    }

    private func startPermissionPolling() {
        stopPermissionPolling()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if Self.hasPermission {
                self.permissionDenied = false
                self.stopPermissionPolling()
                self.activate(duration: self.pendingDuration)
            }
        }
    }

    private func stopPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }

    private func startCleaner(duration: Int) {
        guard let screen = NSScreen.main else { return }

        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: keyboardCleanerCallback,
            userInfo: nil
        ) else {
            permissionDenied = false
            openAccessibilitySettings()
            return
        }

        activeEventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        runLoopSource = source

        let endDate = Date().addingTimeInterval(TimeInterval(duration))

        let window = CleanerWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.onClickAnywhere = { [weak self] in
            DispatchQueue.main.async { self?.deactivate() }
        }

        let overlay = KeyboardCleanerOverlay(endDate: endDate)
        window.contentView = NSHostingView(rootView: overlay)

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window.contentView)

        exitTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(duration),
            repeats: false
        ) { [weak self] _ in
            self?.deactivate()
        }

        cleanerWindow = window
        isActive = true
    }

    func deactivate() {
        guard isActive else { return }
        isActive = false

        if let tap = activeEventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        activeEventTap = nil
        runLoopSource = nil

        exitTimer?.invalidate()
        exitTimer = nil
        cleanerWindow?.orderOut(nil)
        cleanerWindow = nil
    }
}
