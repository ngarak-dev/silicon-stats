import Foundation

/// Optional ScreenCaptureKit-based FPS estimate for a chosen display / window.
///
/// ## Status
/// **Stubbed** in this repository. Implementing requires:
/// - `ScreenCaptureKit` stream with minimal frame handlers
/// - Screen Recording permission (TCC)
/// - Careful CPU budgeting so the HUD itself does not distort metrics
///
/// Until implemented, `currentFPS()` always returns `nil`.
///
/// - API: ScreenCaptureKit (public, macOS 12.3+)
/// - Permissions: Screen Recording
/// - Unavailable behavior: `nil` → overlay `--`
public final class ScreenCaptureFPSProvider: FPSProvider, @unchecked Sendable {
    public let id = "screencapture-fps"
    public let displayName = "ScreenCaptureKit FPS"

    public var status: MetricSourceStatus { .stubbed }

    public init() {}

    public func currentFPS() -> Double? { nil }

    public func displayRefreshRateHz() -> Double? { nil }
}
