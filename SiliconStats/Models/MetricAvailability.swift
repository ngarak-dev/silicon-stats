import Foundation

/// Describes whether a metric can be sourced on the current machine / OS.
public enum MetricSourceStatus: String, Sendable, Equatable {
    case available
    /// Public API exists but returned no data (permission, hardware, or transient).
    case unavailable
    /// Requires private / undocumented interfaces that are not enabled in this build.
    case requiresPrivateAPI
    /// Not yet implemented; UI must show `--` and never invent values.
    case stubbed
    /// Provider is intentionally disabled by the user.
    case disabled
}

public struct MetricAvailability: Equatable, Sendable {
    public var cpuTemperature: MetricSourceStatus
    public var cpuPower: MetricSourceStatus
    public var cpuUtilization: MetricSourceStatus
    public var gpuTemperature: MetricSourceStatus
    public var gpuPower: MetricSourceStatus
    public var gpuUtilization: MetricSourceStatus
    public var packagePower: MetricSourceStatus
    public var memory: MetricSourceStatus
    public var framesPerSecond: MetricSourceStatus
    public var displayRefreshRate: MetricSourceStatus

    public static let allStubbed = MetricAvailability(
        cpuTemperature: .stubbed,
        cpuPower: .stubbed,
        cpuUtilization: .stubbed,
        gpuTemperature: .stubbed,
        gpuPower: .stubbed,
        gpuUtilization: .stubbed,
        packagePower: .stubbed,
        memory: .stubbed,
        framesPerSecond: .stubbed,
        displayRefreshRate: .stubbed
    )
}
