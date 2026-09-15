import Foundation

/// Immutable sample of performance metrics at a point in time.
/// All sensor fields are optional — unavailable values must remain `nil`
/// so the UI can render `--` (or hide the metric) without fabricating data.
public struct PerformanceSnapshot: Equatable, Sendable {
    public var timestamp: Date

    // MARK: CPU
    public var cpuTemperatureCelsius: Double?
    public var cpuPowerWatts: Double?
    public var cpuUtilizationPercent: Double?

    // MARK: GPU
    public var gpuTemperatureCelsius: Double?
    public var gpuPowerWatts: Double?
    public var gpuUtilizationPercent: Double?

    // MARK: System
    public var packagePowerWatts: Double?
    public var memoryUsedBytes: UInt64?
    public var memoryTotalBytes: UInt64?

    // MARK: Display / FPS
    /// Instantaneous frames-per-second estimate from the active `FPSProvider`.
    public var framesPerSecond: Double?
    /// Display refresh rate in Hz when known (not the same as game FPS).
    public var displayRefreshRateHz: Double?

    public init(
        timestamp: Date = Date(),
        cpuTemperatureCelsius: Double? = nil,
        cpuPowerWatts: Double? = nil,
        cpuUtilizationPercent: Double? = nil,
        gpuTemperatureCelsius: Double? = nil,
        gpuPowerWatts: Double? = nil,
        gpuUtilizationPercent: Double? = nil,
        packagePowerWatts: Double? = nil,
        memoryUsedBytes: UInt64? = nil,
        memoryTotalBytes: UInt64? = nil,
        framesPerSecond: Double? = nil,
        displayRefreshRateHz: Double? = nil
    ) {
        self.timestamp = timestamp
        self.cpuTemperatureCelsius = cpuTemperatureCelsius
        self.cpuPowerWatts = cpuPowerWatts
        self.cpuUtilizationPercent = cpuUtilizationPercent
        self.gpuTemperatureCelsius = gpuTemperatureCelsius
        self.gpuPowerWatts = gpuPowerWatts
        self.gpuUtilizationPercent = gpuUtilizationPercent
        self.packagePowerWatts = packagePowerWatts
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.framesPerSecond = framesPerSecond
        self.displayRefreshRateHz = displayRefreshRateHz
    }

    public static let empty = PerformanceSnapshot()

    /// Merges non-nil fields from `other` onto this snapshot (other wins when present).
    public func merging(_ other: PerformanceSnapshot) -> PerformanceSnapshot {
        PerformanceSnapshot(
            timestamp: other.timestamp > timestamp ? other.timestamp : timestamp,
            cpuTemperatureCelsius: other.cpuTemperatureCelsius ?? cpuTemperatureCelsius,
            cpuPowerWatts: other.cpuPowerWatts ?? cpuPowerWatts,
            cpuUtilizationPercent: other.cpuUtilizationPercent ?? cpuUtilizationPercent,
            gpuTemperatureCelsius: other.gpuTemperatureCelsius ?? gpuTemperatureCelsius,
            gpuPowerWatts: other.gpuPowerWatts ?? gpuPowerWatts,
            gpuUtilizationPercent: other.gpuUtilizationPercent ?? gpuUtilizationPercent,
            packagePowerWatts: other.packagePowerWatts ?? packagePowerWatts,
            memoryUsedBytes: other.memoryUsedBytes ?? memoryUsedBytes,
            memoryTotalBytes: other.memoryTotalBytes ?? memoryTotalBytes,
            framesPerSecond: other.framesPerSecond ?? framesPerSecond,
            displayRefreshRateHz: other.displayRefreshRateHz ?? displayRefreshRateHz
        )
    }
}
