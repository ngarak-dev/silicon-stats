import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Memory used / cached / free / wired / compressed via public Mach VM stats.
///
/// Semantics (Activity Monitor–inspired, documented):
/// - **Used**: active + wired + compressed
/// - **Cached**: inactive + speculative (reclaimable file/app cache pressure)
/// - **Free**: free pages
///
/// - API: `host_statistics64` / `HOST_VM_INFO64` (public)
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

        let page = UInt64(vm_kernel_page_size)
        let total = ProcessInfo.processInfo.physicalMemory
        let free = UInt64(stats.free_count) * page
        let active = UInt64(stats.active_count) * page
        let inactive = UInt64(stats.inactive_count) * page
        let speculative = UInt64(stats.speculative_count) * page
        let wired = UInt64(stats.wire_count) * page
        let compressed = UInt64(stats.compressor_page_count) * page
        let cached = inactive &+ speculative
        let used = active &+ wired &+ compressed

        return PerformanceSnapshot(
            memoryUsedBytes: used,
            memoryCachedBytes: cached,
            memoryFreeBytes: free,
            memoryWiredBytes: wired,
            memoryCompressedBytes: compressed,
            memoryTotalBytes: total
        )
        #else
        return PerformanceSnapshot()
        #endif
    }
}
