import AppKit
import SwiftUI

@MainActor
final class BreakWindowController {
    private var windows: [NSWindow] = []
    private let overlay = OverlayWindowController()

    func show(type: BreakType, duration: TimeInterval, allowSkip: Bool, onSkip: @escaping () -> Void) {
        guard windows.isEmpty else { return }

        overlay.show(opacity: AppSettings.shared.overlayOpacity)

        for screen in NSScreen.screens {
            let view = BreakView(
                breakType: type,
                duration: duration,
                allowSkip: allowSkip,
                onSkip: onSkip
            )
            let window = makeBreakWindow(for: screen, content: view)
            window.orderFront(nil)
            windows.append(window)
        }
    }

    func hide() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        overlay.hide()
    }

    // MARK: - Private

    private func makeBreakWindow<V: View>(for screen: NSScreen, content: V) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: content)
        return window
    }
}
