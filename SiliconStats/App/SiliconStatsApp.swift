import AppKit
import SwiftUI
import Combine

@main
final class SiliconStatsApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var overlay: OverlayPanelController!
    private var settingsStore: SettingsStore!
    private var monitor: TelemetryMonitor!
    private var cancellables = Set<AnyCancellable>()

    static func main() {
        let app = NSApplication.shared
        let delegate = SiliconStatsApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        settingsStore = SettingsStore()
        settingsStore.applyDockIconPreference()

        let composite = TelemetryBootstrap.makeComposite(enablePrivateIOReport: false)
        monitor = TelemetryMonitor(settingsStore: settingsStore, composite: composite)
        overlay = OverlayPanelController(settingsStore: settingsStore)

        constructMenu()
        Task { @MainActor in
            self.monitor.start()
        }

        monitor.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                self?.overlay.update(snapshot: snapshot)
            }
            .store(in: &cancellables)

        settingsStore.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.overlay.applyAppearance()
            }
            .store(in: &cancellables)

        if settingsStore.settings.showOverlay {
            overlay.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            self.monitor.stop()
        }
    }

    private func constructMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if let icon = NSImage(named: "MenuBarIcon") {
                icon.isTemplate = true
                icon.size = NSSize(width: 18, height: 18)
                button.image = icon
            } else {
                button.image = NSImage(
                    systemSymbolName: "chip",
                    accessibilityDescription: "Silicon Stats"
                )
                button.image?.isTemplate = true
            }
            button.toolTip = "Silicon Stats"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Overlay", action: #selector(toggleOverlay), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Silicon Stats", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    @objc private func toggleOverlay() {
        settingsStore.update { $0.showOverlay.toggle() }
        overlay.applyAppearance()
    }

    @objc private func openSettings() {
        Task { @MainActor in
            if self.settingsWindow == nil {
                let root = SettingsView(store: self.settingsStore, availability: self.monitor.availability)
                let hosting = NSHostingController(rootView: root)
                let window = NSWindow(contentViewController: hosting)
                window.title = "Silicon Stats"
                window.styleMask = [.titled, .closable, .miniaturizable]
                window.setContentSize(NSSize(width: 440, height: 400))
                window.center()
                self.settingsWindow = window
            }
            // Refresh availability when opening.
            let root = SettingsView(store: self.settingsStore, availability: self.monitor.availability)
            self.settingsWindow?.contentViewController = NSHostingController(rootView: root)
            NSApp.setActivationPolicy(self.settingsStore.settings.showDockIcon ? .regular : .accessory)
            self.settingsWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func refreshNow() {
        Task { @MainActor in
            self.monitor.refreshNow()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
