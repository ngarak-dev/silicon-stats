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
    private let ioReportProvider: IOReportTelemetryProvider
    private var timer: Timer?
    private let settingsStore: SettingsStore
    private var settingsCancellable: AnyCancellable?

    public init(
        settingsStore: SettingsStore,
        composite: CompositeTelemetryProvider,
        ioReportProvider: IOReportTelemetryProvider
    ) {
        self.settingsStore = settingsStore
        self.composite = composite
        self.ioReportProvider = ioReportProvider
        self.availability = composite.availability
        syncPrivateSensors()
        settingsCancellable = settingsStore.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncPrivateSensors()
                self?.restartTimer()
            }
    }

    public func start() {
        composite.start()
        // CPU load needs two samples; take a priming read then a real refresh.
        _ = composite.refresh()
        restartTimer()
        refreshNow()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        composite.stop()
    }

    public func refreshNow() {
        syncPrivateSensors()
        let sample = composite.refresh()
        snapshot = sample
        availability = composite.availability
    }

    private func syncPrivateSensors() {
        let enabled = settingsStore.settings.enablePrivateSensors
        if ioReportProvider.isEnabled != enabled {
            ioReportProvider.isEnabled = enabled
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        let interval = max(0.25, Double(settingsStore.settings.telemetryIntervalMilliseconds) / 1000.0)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNow()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}

/// Factory for production providers — no mock telemetry in release wiring.
public enum TelemetryBootstrap {
    public struct Bundle {
        public let composite: CompositeTelemetryProvider
        public let ioReport: IOReportTelemetryProvider
    }

    public static func makeBundle(enablePrivateIOReport: Bool = false) -> Bundle {
        let ioReport = IOReportTelemetryProvider(isEnabled: enablePrivateIOReport)
        let providers: [any TelemetryProvider] = [
            CPULoadTelemetryProvider(),
            MemoryTelemetryProvider(),
            ThermalStateTelemetryProvider(),
            ioReport
        ]
        let fps: any FPSProvider = DisplayLinkFPSProvider()
        let composite = CompositeTelemetryProvider(providers: providers, fpsProvider: fps)
        return Bundle(composite: composite, ioReport: ioReport)
    }

    public static func makeComposite(enablePrivateIOReport: Bool = false) -> CompositeTelemetryProvider {
        makeBundle(enablePrivateIOReport: enablePrivateIOReport).composite
    }
}
