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
        monitor.start()

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
        monitor.stop()
    }

    private func constructMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "chip",
                accessibilityDescription: "Silicon Stats"
            )
            button.image?.isTemplate = true
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
        if settingsWindow == nil {
            let root = SettingsView(store: settingsStore, availability: monitor.availability)
            let hosting = NSHostingController(rootView: root)
            let window = NSWindow(contentViewController: hosting)
            window.title = "Silicon Stats"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 440, height: 400))
            window.center()
            settingsWindow = window
        }
        // Refresh availability when opening.
        let root = SettingsView(store: settingsStore, availability: monitor.availability)
        settingsWindow?.contentViewController = NSHostingController(rootView: root)
        NSApp.setActivationPolicy(settingsStore.settings.showDockIcon ? .regular : .accessory)
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func refreshNow() {
        monitor.refreshNow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
