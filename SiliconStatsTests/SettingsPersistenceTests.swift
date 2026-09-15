import XCTest
@testable import SiliconStats

final class SettingsPersistenceTests: XCTestCase {
    func testDefaultSettingsRoundTrip() throws {
        let suiteName = "SiliconStatsTests.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        defer { suite.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: suite)
        XCTAssertEqual(store.settings, .default)

        store.update {
            $0.showFPS = false
            $0.overlayOpacity = 0.75
            $0.temperatureUnit = .fahrenheit
            $0.overlayPosition = .bottomTrailing
        }

        let reloaded = SettingsStore(defaults: suite)
        XCTAssertEqual(reloaded.settings.showFPS, false)
        XCTAssertEqual(reloaded.settings.overlayOpacity, 0.75, accuracy: 0.0001)
        XCTAssertEqual(reloaded.settings.temperatureUnit, .fahrenheit)
        XCTAssertEqual(reloaded.settings.overlayPosition, .bottomTrailing)
    }

    func testResetToDefaults() {
        let suiteName = "SiliconStatsTests.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        defer { suite.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: suite)
        store.update { $0.showOverlay = false }
        store.resetToDefaults()
        XCTAssertEqual(store.settings, .default)
    }

    func testClearPersistence() {
        let suiteName = "SiliconStatsTests.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        defer { suite.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: suite)
        store.update { $0.clickThrough = true }
        store.clearPersistence()
        XCTAssertNil(suite.data(forKey: SettingsStore.defaultsKey))
        XCTAssertEqual(store.settings, .default)
    }
}
