import AppKit
import SwiftUI

@MainActor
final class PreBreakWindowController {
    private let preferredWidth: CGFloat = 560
    private let panelHeight: CGFloat = 72
    private let horizontalScreenMargin: CGFloat = 24

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

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let panelWidth = resolvedPanelWidth(for: screen)
        let panel = makePanel(width: panelWidth)
        positionPanel(panel, on: screen, width: panelWidth)
        panel.orderFront(nil)
        window = panel
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
    }

    // MARK: - Private

    private func makePanel(width: CGFloat) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: panelHeight),
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
        }, panelWidth: width)
        panel.contentView = NSHostingView(rootView: view)
        return panel
    }

    private func positionPanel(_ panel: NSPanel, on screen: NSScreen, width: CGFloat) {
        let height = panelHeight
        let x = screen.visibleFrame.midX - width / 2
        let y = screen.visibleFrame.maxY - height - 8
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: false)
    }

    private func resolvedPanelWidth(for screen: NSScreen) -> CGFloat {
        max(420, min(preferredWidth, screen.visibleFrame.width - horizontalScreenMargin * 2))
    }
}
