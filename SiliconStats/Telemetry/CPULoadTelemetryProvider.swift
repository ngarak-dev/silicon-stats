import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// CPU utilization via public Mach host APIs (`host_processor_info`).
///
/// - API: `host_processor_info` / `PROCESSOR_CPU_LOAD_INFO` (public Darwin)
/// - macOS: all modern versions
/// - Chips: Intel + Apple Silicon
/// - Permissions: none
/// - Temperatures / package power are **not** provided here (see IOReport provider).
public final class CPULoadTelemetryProvider: TelemetryProvider, @unchecked Sendable {
    public let id = "cpu-load"
    public let displayName = "CPU Load (Mach)"

    public var availability: MetricAvailability {
        var a = MetricAvailability.allStubbed
        a.cpuUtilization = .available
        return a
    }

    private var previous: host_cpu_load_info?
    private let lock = NSLock()

    public init() {}

    public func sample() -> PerformanceSnapshot {
        guard let load = Self.readCPULoad() else {
            return PerformanceSnapshot()
        }

        lock.lock()
        let prior = previous
        previous = load
        lock.unlock()

        guard let prior else {
            return PerformanceSnapshot()
        }

        let user = Double(load.cpu_ticks.0 &- prior.cpu_ticks.0)
        let system = Double(load.cpu_ticks.1 &- prior.cpu_ticks.1)
        let idle = Double(load.cpu_ticks.2 &- prior.cpu_ticks.2)
        let nice = Double(load.cpu_ticks.3 &- prior.cpu_ticks.3)
        let total = user + system + idle + nice
        guard total > 0 else {
            return PerformanceSnapshot()
        }
        let busy = (user + system + nice) / total * 100.0
        return PerformanceSnapshot(cpuUtilizationPercent: busy)
    }

    private static func readCPULoad() -> host_cpu_load_info? {
        #if canImport(Darwin)
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size
        )
        var info = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return info
        #else
        return nil
        #endif
    }
}
