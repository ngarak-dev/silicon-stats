import Foundation

/// Coarse thermal pressure from public `ProcessInfo` APIs.
///
/// Does **not** provide °C readings — only a qualitative state that can be
/// surfaced in settings/diagnostics. Overlay temperature fields stay `nil`.
///
/// - API: `ProcessInfo.thermalState` (public)
/// - macOS 10.15+
/// - Permissions: none
public final class ThermalStateTelemetryProvider: TelemetryProvider, @unchecked Sendable {
    public let id = "thermal-state"
    public let displayName = "Thermal State (ProcessInfo)"

    /// Latest qualitative state for diagnostics UI (not shown as °C).
    public private(set) var lastThermalState: ProcessInfo.ThermalState = .nominal

    public var availability: MetricAvailability {
        // Explicitly unavailable for temperature °C — we refuse to map
        // thermalState → fake Celsius.
        var a = MetricAvailability.allStubbed
        a.cpuTemperature = .unavailable
        a.gpuTemperature = .unavailable
        return a
    }

    public init() {}

    public func sample() -> PerformanceSnapshot {
        lastThermalState = ProcessInfo.processInfo.thermalState
        return PerformanceSnapshot()
    }
}
