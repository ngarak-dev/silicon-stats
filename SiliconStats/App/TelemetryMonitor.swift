import Foundation
import Combine
#if canImport(AppKit)
import AppKit
#endif

/// Owns telemetry polling off the main thread and publishes snapshots for the HUD.
@MainActor
public final class TelemetryMonitor: ObservableObject {
    @Published public private(set) var snapshot: PerformanceSnapshot = .empty
    @Published public private(set) var availability: MetricAvailability

    private let composite: CompositeTelemetryProvider
    private var timer: Timer?
    private let settingsStore: SettingsStore
    private var settingsCancellable: AnyCancellable?

    public init(settingsStore: SettingsStore, composite: CompositeTelemetryProvider) {
        self.settingsStore = settingsStore
        self.composite = composite
        self.availability = composite.availability
        settingsCancellable = settingsStore.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.restartTimer()
            }
    }

    public func start() {
        composite.start()
        restartTimer()
        refreshNow()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        composite.stop()
    }

    public func refreshNow() {
        let sample = composite.refresh()
        snapshot = sample
        availability = composite.availability
    }

    private func restartTimer() {
        timer?.invalidate()
        let interval = max(0.25, Double(settingsStore.settings.telemetryIntervalMilliseconds) / 1000.0)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshNow()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}

/// Factory for production providers — no mock telemetry in release wiring.
public enum TelemetryBootstrap {
    public static func makeComposite(enablePrivateIOReport: Bool = false) -> CompositeTelemetryProvider {
        let providers: [any TelemetryProvider] = [
            CPULoadTelemetryProvider(),
            MemoryTelemetryProvider(),
            ThermalStateTelemetryProvider(),
            IOReportTelemetryProvider(isEnabled: enablePrivateIOReport)
        ]
        // Prefer DisplayLink for local refresh cadence; ScreenCapture remains stubbed.
        let fps: any FPSProvider = DisplayLinkFPSProvider()
        return CompositeTelemetryProvider(providers: providers, fpsProvider: fps)
    }
}
