import AppKit
import SwiftData
import SwiftUI

@MainActor
final class BreakWindowController {
    private var windows: [NSWindow] = []
    private let overlay = OverlayWindowController()

    func show(type: BreakType, duration: TimeInterval, allowSkip: Bool, onSkip: @escaping () -> Void) {
        guard windows.isEmpty else { return }

        overlay.show(opacity: AppSettings.shared.overlayOpacity)

        let stereogramData = pickStereogram(for: type)

        for screen in NSScreen.screens {
            let window: NSWindow
            if let (image, source, author) = stereogramData {
                let ctx = ModelContext(DataStack.container)
                let service = CatalogService.shared
                let view = StereogramBreakView(
                    image: image,
                    source: source,
                    author: author,
                    duration: duration,
                    allowSkip: allowSkip,
                    onSkip: onSkip,
                    pickNext: {
                        guard let (img, url) = StereogramPicker.pick(
                            from: service.images, service: service, context: ctx
                        ) else { return nil }
                        guard let nsImage = NSImage(contentsOf: url) else { return nil }
                        return (nsImage, img.source, img.author)
                    }
                )
                window = makeBreakWindow(for: screen, content: view)
            } else {
                let view = BreakView(
                    breakType: type,
                    duration: duration,
                    allowSkip: allowSkip,
                    onSkip: onSkip
                )
                window = makeBreakWindow(for: screen, content: view)
            }
            window.orderFront(nil)
            windows.append(window)
        }
    }

    private func pickStereogram(for type: BreakType) -> (NSImage, String?, String?)? {
        guard type == .long, AppSettings.shared.stereogramsEnabled else { return nil }
        let service = CatalogService.shared
        let ctx = ModelContext(DataStack.container)
        guard let (img, url) = StereogramPicker.pick(from: service.images, service: service, context: ctx),
              let nsImage = NSImage(contentsOf: url)
        else { return nil }
        return (nsImage, img.source, img.author)
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
