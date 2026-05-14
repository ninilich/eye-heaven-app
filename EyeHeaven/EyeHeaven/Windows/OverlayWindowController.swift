import AppKit

@MainActor
final class OverlayWindowController {
    private var windows: [NSWindow] = []

    func show(opacity: Double) {
        hide()
        for screen in NSScreen.screens {
            let window = makeOverlayWindow(for: screen, opacity: opacity)
            window.orderFront(nil)
            windows.append(window)
        }
    }

    func hide() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }

    // MARK: - Private

    private func makeOverlayWindow(for screen: NSScreen, opacity: Double) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = NSColor.black.withAlphaComponent(opacity)
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return window
    }
}
