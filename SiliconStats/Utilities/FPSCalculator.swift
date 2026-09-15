import Foundation

/// Pure FPS math helpers shared by providers and unit tests.
public enum FPSCalculator {
    /// Computes frames per second from monotonically increasing timestamps.
    /// Returns `nil` when fewer than two samples or non-positive duration.
    public static func framesPerSecond(timestamps: [CFTimeInterval]) -> Double? {
        guard timestamps.count >= 2,
              let first = timestamps.first,
              let last = timestamps.last,
              last > first else {
            return nil
        }
        let duration = last - first
        let frames = Double(timestamps.count - 1)
        let fps = frames / duration
        guard fps.isFinite, fps >= 0 else { return nil }
        return fps
    }

    /// Exponential moving average.
    public static func smooth(previous: Double?, sample: Double, alpha: Double = 0.2) -> Double {
        let clampedAlpha = min(max(alpha, 0), 1)
        guard let previous else { return sample }
        return previous * (1 - clampedAlpha) + sample * clampedAlpha
    }
}
