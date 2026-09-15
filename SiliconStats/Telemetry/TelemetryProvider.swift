import Foundation

/// Abstraction over Apple Silicon / system telemetry sources.
///
/// Implementations must:
/// - Return `nil` for any metric they cannot read (never fabricate).
/// - Document private/undocumented API usage in `Docs/TELEMETRY.md`.
/// - Be safe to call from a background queue; UI observes published snapshots.
public protocol TelemetryProvider: AnyObject, Sendable {
    var id: String { get }
    var displayName: String { get }
    var availability: MetricAvailability { get }

    /// Starts periodic sampling if needed. Idempotent.
    func start()
    /// Stops sampling and releases resources. Idempotent.
    func stop()

    /// Captures a single snapshot. Fields the provider does not own stay `nil`.
    func sample() -> PerformanceSnapshot
}

/// Default no-op lifecycle for providers that sample on demand only.
public extension TelemetryProvider {
    func start() {}
    func stop() {}
}
