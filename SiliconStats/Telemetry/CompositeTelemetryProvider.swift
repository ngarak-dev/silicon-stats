import Foundation

/// Merges samples from multiple `TelemetryProvider`s and an optional `FPSProvider`.
/// Telemetry refresh is independent of UI redraws — callers should schedule
/// `refresh()` on a timer / background queue and publish the result.
public final class CompositeTelemetryProvider: @unchecked Sendable {
    public let providers: [any TelemetryProvider]
    public let fpsProvider: (any FPSProvider)?

    private let lock = NSLock()
    private var latest: PerformanceSnapshot = .empty

    public init(
        providers: [any TelemetryProvider],
        fpsProvider: (any FPSProvider)? = nil
    ) {
        self.providers = providers
        self.fpsProvider = fpsProvider
    }

    public var availability: MetricAvailability {
        var merged = MetricAvailability.allStubbed
        for provider in providers {
            let a = provider.availability
            merged.cpuTemperature = prefer(merged.cpuTemperature, a.cpuTemperature)
            merged.cpuPower = prefer(merged.cpuPower, a.cpuPower)
            merged.cpuUtilization = prefer(merged.cpuUtilization, a.cpuUtilization)
            merged.gpuTemperature = prefer(merged.gpuTemperature, a.gpuTemperature)
            merged.gpuPower = prefer(merged.gpuPower, a.gpuPower)
            merged.gpuUtilization = prefer(merged.gpuUtilization, a.gpuUtilization)
            merged.packagePower = prefer(merged.packagePower, a.packagePower)
            merged.memory = prefer(merged.memory, a.memory)
        }
        if let fpsProvider {
            merged.framesPerSecond = fpsProvider.status
            merged.displayRefreshRate = fpsProvider.status == .available
                ? .available
                : fpsProvider.status
        }
        return merged
    }

    public func start() {
        providers.forEach { $0.start() }
        fpsProvider?.start()
    }

    public func stop() {
        providers.forEach { $0.stop() }
        fpsProvider?.stop()
    }

    @discardableResult
    public func refresh() -> PerformanceSnapshot {
        var snapshot = PerformanceSnapshot(timestamp: Date())
        for provider in providers {
            snapshot = snapshot.merging(provider.sample())
        }
        if let fpsProvider {
            snapshot.framesPerSecond = fpsProvider.currentFPS()
            snapshot.displayRefreshRateHz = fpsProvider.displayRefreshRateHz()
        }
        lock.lock()
        latest = snapshot
        lock.unlock()
        return snapshot
    }

    public func currentSnapshot() -> PerformanceSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return latest
    }

    private func prefer(_ current: MetricSourceStatus, _ incoming: MetricSourceStatus) -> MetricSourceStatus {
        // Prefer concrete availability over stubbed/unavailable.
        let rank: (MetricSourceStatus) -> Int = { status in
            switch status {
            case .available: return 4
            case .requiresPrivateAPI: return 3
            case .unavailable: return 2
            case .disabled: return 1
            case .stubbed: return 0
            }
        }
        return rank(incoming) > rank(current) ? incoming : current
    }
}
