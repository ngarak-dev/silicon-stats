import Foundation

/// Abstraction over frame-rate measurement.
///
/// System-wide game FPS is not available via public macOS APIs. Concrete
/// providers document what they actually measure (display refresh, local
/// Metal drawable cadence, etc.). Unavailable → `nil` FPS, never invented.
public protocol FPSProvider: AnyObject, Sendable {
    var id: String { get }
    var displayName: String { get }
    var status: MetricSourceStatus { get }

    func start()
    func stop()

    /// Latest FPS estimate, or `nil` when not measurable.
    func currentFPS() -> Double?

    /// Display refresh rate in Hz when known.
    func displayRefreshRateHz() -> Double?
}

public extension FPSProvider {
    func start() {}
    func stop() {}
    func displayRefreshRateHz() -> Double? { nil }
}
