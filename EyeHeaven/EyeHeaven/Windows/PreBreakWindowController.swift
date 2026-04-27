import AppKit
import SwiftUI

@MainActor
final class PreBreakWindowController {
    private var window: NSPanel?
    private let model = PreBreakModel()

    func show(
        type: BreakType,
        timeRemaining: TimeInterval,
        warningDuration: TimeInterval,
        onClose: @escaping () -> Void,
        onStartNow: (() -> Void)?,
        onPostpone: (() -> Void)?,
        onSkip: (() -> Void)?
    ) {
        model.breakType = type
        model.timeRemaining = timeRemaining
        model.warningDuration = warningDuration
        model.onClose = onClose
        model.onStartNow = onStartNow
        model.onPostpone = onPostpone
        model.onSkip = onSkip

        guard window == nil else { return }

        let panel = makePanel()
        positionPanel(panel)
        panel.orderFront(nil)
        window = panel
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
    }

    // MARK: - Private

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 72),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = PreBreakView(model: model, onClose: { [weak self] in
            self?.model.onClose?()
            self?.hide()
        })
        panel.contentView = NSHostingView(rootView: view)
        return panel
    }

    private func positionPanel(_ panel: NSPanel) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let width: CGFloat = 440
        let height: CGFloat = 72
        let x = screen.visibleFrame.midX - width / 2
        let y = screen.visibleFrame.maxY - height - 8
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: false)
    }
}
