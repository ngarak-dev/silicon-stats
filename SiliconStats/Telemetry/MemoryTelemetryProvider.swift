import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Physical memory pressure via public Mach `host_statistics64` APIs.
///
/// - API: `host_statistics64` / `HOST_VM_INFO64` (public)
/// - Does not provide CPU/GPU thermal or power data.
public final class MemoryTelemetryProvider: TelemetryProvider, @unchecked Sendable {
    public let id = "memory"
    public let displayName = "Memory (Mach VM)"

    public var availability: MetricAvailability {
        var a = MetricAvailability.allStubbed
        a.memory = .available
        return a
    }

    public init() {}

    public func sample() -> PerformanceSnapshot {
        #if canImport(Darwin)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride
        )
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else {
            return PerformanceSnapshot()
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let total = ProcessInfo.processInfo.physicalMemory
        let free = UInt64(stats.free_count) * pageSize
        let speculative = UInt64(stats.speculative_count) * pageSize
        let used = total > (free + speculative) ? total - free - speculative : 0
        return PerformanceSnapshot(memoryUsedBytes: used, memoryTotalBytes: total)
        #else
        return PerformanceSnapshot()
        #endif
    }
}
