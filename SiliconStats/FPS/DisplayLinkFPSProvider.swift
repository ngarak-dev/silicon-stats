import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(CoreVideo)
import CoreVideo
#endif

/// Measures **local display refresh cadence** via `CVDisplayLink`, not
/// system-wide game FPS.
///
/// ## What this reports
/// - `displayRefreshRateHz`: the active display's refresh rate when the link runs
/// - `currentFPS()`: smoothed callback rate of this process's display link
///
/// ## What this does **not** report
/// Frame rate of other applications / full-screen games. Capturing that
/// requires ScreenCaptureKit frame timestamps or private HUD hooks — see
/// `ScreenCaptureFPSProvider` and `Docs/TELEMETRY.md`.
///
/// - API: `CVDisplayLink` (public CoreVideo)
/// - macOS: 10.4+ (modern usage 11+)
/// - Permissions: none
/// - Unavailable: returns `nil` until `start()` succeeds
public final class DisplayLinkFPSProvider: FPSProvider, @unchecked Sendable {
    public let id = "display-link"
    public let displayName = "Display Link FPS"

    public private(set) var status: MetricSourceStatus = .unavailable

    private let lock = NSLock()
    private var link: CVDisplayLink?
    private var frameTimestamps: [CFTimeInterval] = []
    private var refreshHz: Double?
    private var smoothedFPS: Double?
    private let maxSamples = 120

    public init() {}

    public func start() {
        #if canImport(CoreVideo)
        guard link == nil else { return }
        var newLink: CVDisplayLink?
        guard CVDisplayLinkCreateWithActiveCGDisplays(&newLink) == kCVReturnSuccess,
              let newLink else {
            status = .unavailable
            return
        }

        let callback: CVDisplayLinkOutputCallback = { _, inNow, _, _, _, userInfo in
            guard let userInfo else { return kCVReturnSuccess }
            let provider = Unmanaged<DisplayLinkFPSProvider>.fromOpaque(userInfo).takeUnretainedValue()
            let stamp = inNow.pointee
            guard stamp.videoTimeScale != 0 else { return kCVReturnSuccess }
            let timestamp = CFTimeInterval(stamp.videoTime) / CFTimeInterval(stamp.videoTimeScale)
            provider.recordFrame(at: timestamp)
            return kCVReturnSuccess
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(newLink, callback, context)
        CVDisplayLinkStart(newLink)
        link = newLink
        status = .available

        let period = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(newLink)
        if period.timescale != 0 {
            let hz = Double(period.timescale) / Double(period.value)
            lock.lock()
            refreshHz = hz
            lock.unlock()
        }
        #else
        status = .unavailable
        #endif
    }

    public func stop() {
        #if canImport(CoreVideo)
        if let link {
            CVDisplayLinkStop(link)
        }
        link = nil
        #endif
        lock.lock()
        frameTimestamps.removeAll()
        smoothedFPS = nil
        lock.unlock()
        status = .unavailable
    }

    public func currentFPS() -> Double? {
        lock.lock()
        defer { lock.unlock() }
        return smoothedFPS
    }

    public func displayRefreshRateHz() -> Double? {
        lock.lock()
        defer { lock.unlock() }
        return refreshHz
    }

    private func recordFrame(at timestamp: CFTimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        frameTimestamps.append(timestamp)
        if frameTimestamps.count > maxSamples {
            frameTimestamps.removeFirst(frameTimestamps.count - maxSamples)
        }
        guard frameTimestamps.count >= 2,
              let first = frameTimestamps.first,
              let last = frameTimestamps.last,
              last > first else {
            return
        }
        let duration = last - first
        let frames = Double(frameTimestamps.count - 1)
        guard duration > 0 else { return }
        let instant = frames / duration
        if let existing = smoothedFPS {
            smoothedFPS = existing * 0.8 + instant * 0.2
        } else {
            smoothedFPS = instant
        }
    }
}
