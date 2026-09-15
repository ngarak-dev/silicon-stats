import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Aggregate + per-core CPU utilization via public Mach `host_processor_info`.
///
/// - API: `host_processor_info` / `PROCESSOR_CPU_LOAD_INFO` (public Darwin)
/// - Permissions: none
/// - Temperatures / package power are **not** provided here (see IOReport).
public final class CPULoadTelemetryProvider: TelemetryProvider, @unchecked Sendable {
    public let id = "cpu-load"
    public let displayName = "CPU Load (Mach)"

    public var availability: MetricAvailability {
        var a = MetricAvailability.allStubbed
        a.cpuUtilization = .available
        return a
    }

    private var previousTicks: [[UInt32]]?
    private let lock = NSLock()

    public init() {}

    public func sample() -> PerformanceSnapshot {
        guard let current = Self.readPerCoreTicks() else {
            return PerformanceSnapshot()
        }

        lock.lock()
        let prior = previousTicks
        previousTicks = current
        lock.unlock()

        guard let prior, prior.count == current.count, !prior.isEmpty else {
            return PerformanceSnapshot()
        }

        var perCore: [Double] = []
        perCore.reserveCapacity(current.count)
        var busySum = 0.0
        var totalSum = 0.0

        for index in current.indices {
            let now = current[index]
            let then = prior[index]
            guard now.count >= 4, then.count >= 4 else { continue }
            let user = Double(now[0] &- then[0])
            let system = Double(now[1] &- then[1])
            let idle = Double(now[2] &- then[2])
            let nice = Double(now[3] &- then[3])
            let total = user + system + idle + nice
            guard total > 0 else {
                perCore.append(0)
                continue
            }
            let busy = user + system + nice
            perCore.append(busy / total * 100.0)
            busySum += busy
            totalSum += total
        }

        let aggregate = totalSum > 0 ? busySum / totalSum * 100.0 : nil
        return PerformanceSnapshot(
            cpuUtilizationPercent: aggregate,
            perCoreCPUUtilizationPercent: perCore.isEmpty ? nil : perCore
        )
    }

    private static func readPerCoreTicks() -> [[UInt32]]? {
        #if canImport(Darwin)
        var cpuCount: natural_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let kr = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &infoArray,
            &infoCount
        )
        guard kr == KERN_SUCCESS, let infoArray, cpuCount > 0 else { return nil }
        defer {
            let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: infoArray), size)
        }

        let states = Int(CPU_STATE_MAX)
        var cores: [[UInt32]] = []
        cores.reserveCapacity(Int(cpuCount))
        for core in 0..<Int(cpuCount) {
            let base = core * states
            guard base + 3 < Int(infoCount) else { break }
            let user = UInt32(bitPattern: infoArray[base + Int(CPU_STATE_USER)])
            let system = UInt32(bitPattern: infoArray[base + Int(CPU_STATE_SYSTEM)])
            let idle = UInt32(bitPattern: infoArray[base + Int(CPU_STATE_IDLE)])
            let nice = UInt32(bitPattern: infoArray[base + Int(CPU_STATE_NICE)])
            cores.append([user, system, idle, nice])
        }
        return cores.isEmpty ? nil : cores
        #else
        return nil
        #endif
    }
}
