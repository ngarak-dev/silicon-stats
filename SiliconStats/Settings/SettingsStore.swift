import Combine
import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(ServiceManagement)
import ServiceManagement
#endif

public final class SettingsStore: ObservableObject {
    public static let defaultsKey = "SiliconStats.AppSettings"

    @Published public private(set) var settings: AppSettings {
        didSet { persist() }
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? decoder.decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    public func update(_ mutate: (inout AppSettings) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
    }

    public func resetToDefaults() {
        settings = .default
    }

    /// Test helper: clear persisted blob.
    public func clearPersistence() {
        defaults.removeObject(forKey: Self.defaultsKey)
        settings = .default
    }

    public func applyDockIconPreference() {
        #if canImport(AppKit)
        let policy: NSApplication.ActivationPolicy = settings.showDockIcon ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
        #endif
    }

    public func applyLaunchAtLogin() {
        #if canImport(ServiceManagement)
        if #available(macOS 13.0, *) {
            do {
                if settings.launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Launch-at-login can fail in unsigned debug builds; ignore.
            }
        }
        #endif
    }

    private func persist() {
        if let data = try? encoder.encode(settings) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
