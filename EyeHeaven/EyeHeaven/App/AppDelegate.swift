import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = BreakScheduler.shared
        setupStatusItem()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeHeaven")

        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let nextBreak = BreakScheduler.shared.nextBreakDescription
        menu.addItem(menuItem(title: nextBreak, symbol: "eye.fill"))
        menu.addItem(.separator())

        let isPaused = BreakScheduler.shared.isPaused
        let pauseTitle = isPaused ? String(localized: "menu.resume") : String(localized: "menu.pause")
        let pauseSymbol = isPaused ? "play.fill" : "pause.fill"
        menu.addItem(menuItem(title: pauseTitle, symbol: pauseSymbol, action: #selector(togglePause)))
        menu.addItem(menuItem(title: String(localized: "menu.skip_next"), symbol: "forward.end.fill", action: #selector(skipNext)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: String(localized: "menu.settings"), symbol: "gearshape", action: #selector(openSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: String(localized: "menu.quit"), symbol: "power", action: #selector(NSApplication.terminate(_:)), key: "q"))
    }

    private func menuItem(
        title: String,
        symbol: String,
        action: Selector? = nil,
        key: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return item
    }

    // MARK: - Actions

    @objc private func togglePause() {
        BreakScheduler.shared.togglePause()
    }

    @objc private func skipNext() {
        BreakScheduler.shared.skipNextBreak()
    }

    @objc func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "settings.title")
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }
}
