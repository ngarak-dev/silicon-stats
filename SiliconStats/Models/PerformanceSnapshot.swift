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
    /// Per-logical-core busy percentages (0…100), same sample window as aggregate.
    public var perCoreCPUUtilizationPercent: [Double]?

    // MARK: GPU
    public var gpuTemperatureCelsius: Double?
    public var gpuPowerWatts: Double?
    public var gpuUtilizationPercent: Double?

    // MARK: System / memory
    public var packagePowerWatts: Double?
    public var memoryUsedBytes: UInt64?
    public var memoryCachedBytes: UInt64?
    public var memoryFreeBytes: UInt64?
    public var memoryWiredBytes: UInt64?
    public var memoryCompressedBytes: UInt64?
    public var memoryTotalBytes: UInt64?

    // MARK: Display / FPS
    public var framesPerSecond: Double?
    public var displayRefreshRateHz: Double?

    public init(
        timestamp: Date = Date(),
        cpuTemperatureCelsius: Double? = nil,
        cpuPowerWatts: Double? = nil,
        cpuUtilizationPercent: Double? = nil,
        perCoreCPUUtilizationPercent: [Double]? = nil,
        gpuTemperatureCelsius: Double? = nil,
        gpuPowerWatts: Double? = nil,
        gpuUtilizationPercent: Double? = nil,
        packagePowerWatts: Double? = nil,
        memoryUsedBytes: UInt64? = nil,
        memoryCachedBytes: UInt64? = nil,
        memoryFreeBytes: UInt64? = nil,
        memoryWiredBytes: UInt64? = nil,
        memoryCompressedBytes: UInt64? = nil,
        memoryTotalBytes: UInt64? = nil,
        framesPerSecond: Double? = nil,
        displayRefreshRateHz: Double? = nil
    ) {
        self.timestamp = timestamp
        self.cpuTemperatureCelsius = cpuTemperatureCelsius
        self.cpuPowerWatts = cpuPowerWatts
        self.cpuUtilizationPercent = cpuUtilizationPercent
        self.perCoreCPUUtilizationPercent = perCoreCPUUtilizationPercent
        self.gpuTemperatureCelsius = gpuTemperatureCelsius
        self.gpuPowerWatts = gpuPowerWatts
        self.gpuUtilizationPercent = gpuUtilizationPercent
        self.packagePowerWatts = packagePowerWatts
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryCachedBytes = memoryCachedBytes
        self.memoryFreeBytes = memoryFreeBytes
        self.memoryWiredBytes = memoryWiredBytes
        self.memoryCompressedBytes = memoryCompressedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.framesPerSecond = framesPerSecond
        self.displayRefreshRateHz = displayRefreshRateHz
    }

    public static let empty = PerformanceSnapshot()

    public func merging(_ other: PerformanceSnapshot) -> PerformanceSnapshot {
        PerformanceSnapshot(
            timestamp: other.timestamp > timestamp ? other.timestamp : timestamp,
            cpuTemperatureCelsius: other.cpuTemperatureCelsius ?? cpuTemperatureCelsius,
            cpuPowerWatts: other.cpuPowerWatts ?? cpuPowerWatts,
            cpuUtilizationPercent: other.cpuUtilizationPercent ?? cpuUtilizationPercent,
            perCoreCPUUtilizationPercent: other.perCoreCPUUtilizationPercent ?? perCoreCPUUtilizationPercent,
            gpuTemperatureCelsius: other.gpuTemperatureCelsius ?? gpuTemperatureCelsius,
            gpuPowerWatts: other.gpuPowerWatts ?? gpuPowerWatts,
            gpuUtilizationPercent: other.gpuUtilizationPercent ?? gpuUtilizationPercent,
            packagePowerWatts: other.packagePowerWatts ?? packagePowerWatts,
            memoryUsedBytes: other.memoryUsedBytes ?? memoryUsedBytes,
            memoryCachedBytes: other.memoryCachedBytes ?? memoryCachedBytes,
            memoryFreeBytes: other.memoryFreeBytes ?? memoryFreeBytes,
            memoryWiredBytes: other.memoryWiredBytes ?? memoryWiredBytes,
            memoryCompressedBytes: other.memoryCompressedBytes ?? memoryCompressedBytes,
            memoryTotalBytes: other.memoryTotalBytes ?? memoryTotalBytes,
            framesPerSecond: other.framesPerSecond ?? framesPerSecond,
            displayRefreshRateHz: other.displayRefreshRateHz ?? displayRefreshRateHz
        )
    }
}
