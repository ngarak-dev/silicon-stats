import Foundation
#if canImport(IOKit)
import IOKit
#endif

/// Apple Silicon CPU/GPU temperature and power via **private** IOReport /
/// AppleCLPC interfaces.
///
/// ## Status in this build
/// Sampling is **disabled by default**. Public builds return empty snapshots
/// (`nil` fields → UI `--`). Enable only after validating on target hardware.
///
/// ## Documentation
/// | Item | Detail |
/// |---|---|
/// | API | `IOReportCopyChannelsInGroup`, `IOReportCreateSubscription`, channel groups such as `Energy Model` / `CPU Stats` / `GPU Stats` (undocumented; reverse-engineered community knowledge) |
/// | Framework | Private `IOReport` (linked via dlsym / weak, not a public SDK module) |
/// | macOS | Observed on macOS 12–15; channel names drift across releases |
/// | Chips | Apple Silicon M1–M4 (M5 untested). Intel Macs use different SMC keys |
/// | Permissions | Often needs the app outside App Sandbox, or Full Disk / performance tooling entitlement. Sandboxed Mac App Store builds typically cannot read these channels |
/// | Unavailable behavior | Returns `PerformanceSnapshot()` with all optionals `nil`; overlay shows `--` |
/// | Risk | Private API — App Store rejection risk; may break on OS updates |
///
/// See `Docs/TELEMETRY.md` for the full matrix and enablement steps.
public final class IOReportTelemetryProvider: TelemetryProvider, @unchecked Sendable {
    public let id = "ioreport-as"
    public let displayName = "IOReport (Private Apple Silicon)"

    /// When `false` (default), `sample()` never invents values and reports
    /// `requiresPrivateAPI` availability.
    public var isEnabled: Bool

    public var availability: MetricAvailability {
        var a = MetricAvailability.allStubbed
        let status: MetricSourceStatus = isEnabled ? .requiresPrivateAPI : .requiresPrivateAPI
        // Even when enabled, until channel parsing is validated on-device we
        // advertise requiresPrivateAPI rather than .available.
        a.cpuTemperature = status
        a.cpuPower = status
        a.gpuTemperature = status
        a.gpuPower = status
        a.gpuUtilization = status
        a.packagePower = status
        return a
    }

    public init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    public func sample() -> PerformanceSnapshot {
        guard isEnabled else {
            return PerformanceSnapshot()
        }
        // Intentionally unimplemented without verified channel maps.
        // Wiring dlsym'd IOReport here without hardware validation would
        // either crash or tempt fabricated fallbacks — both are disallowed.
        return samplePrivateChannels()
    }

    /// Hook for future on-device IOReport channel reads.
    /// Must return only values actually parsed from firmware channels.
    private func samplePrivateChannels() -> PerformanceSnapshot {
        #if canImport(IOKit)
        // Placeholder: private IOReport symbols are not linked in this
        // open-source skeleton. Contributors should load via dlsym and map
        // channels documented in Docs/TELEMETRY.md after hardware validation.
        return PerformanceSnapshot()
        #else
        return PerformanceSnapshot()
        #endif
    }
}
