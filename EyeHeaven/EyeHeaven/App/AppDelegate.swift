import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_: Notification) {
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
        if settingsWindowController == nil {
            settingsWindowController = makeSettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeSettingsWindowController() -> NSWindowController {
        let tabVC = NSTabViewController()
        tabVC.tabStyle = .toolbar

        func addTab(_ view: some View, label: String, symbol: String) {
            let vc = NSHostingController(rootView: view)
            let item = NSTabViewItem(viewController: vc)
            item.label = label
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            tabVC.addTabViewItem(item)
        }

        addTab(BreaksSettingsView(),
               label: String(localized: "settings.tab.breaks"),
               symbol: "clock.fill")
        addTab(SystemSettingsView(),
               label: String(localized: "settings.section.system"),
               symbol: "gear")
        addTab(StereogramsSettingsView(),
               label: String(localized: "settings.section.stereograms"),
               symbol: "eye.fill")
        addTab(AboutSettingsView(),
               label: String(localized: "settings.tab.about"),
               symbol: "info.circle")

        let window = NSWindow(contentViewController: tabVC)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        return NSWindowController(window: window)
    }
}
