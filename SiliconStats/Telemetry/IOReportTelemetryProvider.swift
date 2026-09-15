import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Apple Silicon CPU/GPU temperature and power via **private** IOReport.
///
/// Loads symbols with `dlsym` at runtime (no public SDK link). When enabled,
/// samples Energy Model / temperature-like channels best-effort. Any channel
/// that cannot be parsed stays `nil` — never fabricated.
///
/// See `Docs/TELEMETRY.md` for the full matrix, risks, and enablement notes.
public final class IOReportTelemetryProvider: TelemetryProvider, @unchecked Sendable {
    public let id = "ioreport-as"
    public let displayName = "IOReport (Private Apple Silicon)"

    /// When `false` (default), `sample()` returns an empty snapshot.
    public var isEnabled: Bool {
        didSet {
            if isEnabled { IOReportRuntime.shared.ensurePrepared() }
        }
    }

    private let lock = NSLock()
    private var previousEnergy: [String: Int64] = [:]
    private var previousSampleAt: Date?

    public var availability: MetricAvailability {
        var a = MetricAvailability.allStubbed
        let status: MetricSourceStatus = isEnabled ? .requiresPrivateAPI : .disabled
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
        if isEnabled { IOReportRuntime.shared.ensurePrepared() }
    }

    public func sample() -> PerformanceSnapshot {
        guard isEnabled else { return PerformanceSnapshot() }
        return samplePrivateChannels()
    }

    private func samplePrivateChannels() -> PerformanceSnapshot {
        #if canImport(Darwin)
        let runtime = IOReportRuntime.shared
        runtime.ensurePrepared()
        guard runtime.isReady else { return PerformanceSnapshot() }

        let energy = runtime.sampleSubscribed(named: "Energy Model")
        let temps = runtime.sampleSubscribed(named: nil) // all non-energy subscriptions

        let now = Date()
        lock.lock()
        let prior = previousEnergy
        let priorAt = previousSampleAt
        previousEnergy = energy
        previousSampleAt = now
        lock.unlock()

        var cpuPower: Double?
        var gpuPower: Double?
        var packagePower: Double?

        if let priorAt {
            let dt = now.timeIntervalSince(priorAt)
            if dt > 0.05, dt < 10 {
                cpuPower = powerWatts(deltaMicroJoules: delta(energy, prior) { n in
                    let x = n.lowercased()
                    return x.contains("cpu") && !x.contains("gpu")
                }, dt: dt)
                gpuPower = powerWatts(deltaMicroJoules: delta(energy, prior) { $0.lowercased().contains("gpu") }, dt: dt)
                packagePower = powerWatts(deltaMicroJoules: delta(energy, prior) { n in
                    let x = n.lowercased()
                    return x.contains("cpu") || x.contains("gpu") || x.contains("ane")
                        || x.contains("dram") || x.contains("package") || x.contains("total")
                }, dt: dt)
            }
        }

        return PerformanceSnapshot(
            cpuTemperatureCelsius: averageCelsius(temps) { n in
                let x = n.lowercased()
                return (x.contains("cpu") || x.contains("soc") || x.contains("die")) && !x.contains("gpu")
            },
            cpuPowerWatts: cpuPower,
            gpuTemperatureCelsius: averageCelsius(temps) { $0.lowercased().contains("gpu") },
            gpuPowerWatts: gpuPower,
            packagePowerWatts: packagePower
        )
        #else
        return PerformanceSnapshot()
        #endif
    }

    private func delta(
        _ current: [String: Int64],
        _ previous: [String: Int64],
        match: (String) -> Bool
    ) -> Double? {
        var sum: Double = 0
        var hit = false
        for (name, value) in current where match(name) {
            guard let old = previous[name], value >= old else { continue }
            sum += Double(value - old)
            hit = true
        }
        return hit ? sum : nil
    }

    private func powerWatts(deltaMicroJoules: Double?, dt: TimeInterval) -> Double? {
        guard let deltaMicroJoules, dt > 0 else { return nil }
        let watts = (deltaMicroJoules / 1_000_000.0) / dt
        guard watts.isFinite, watts >= 0, watts < 500 else { return nil }
        return watts
    }

    private func averageCelsius(
        _ counters: [String: Int64],
        match: (String) -> Bool
    ) -> Double? {
        var values: [Double] = []
        for (name, raw) in counters where match(name) {
            var c = Double(raw)
            if c > 200 { c /= 1000.0 }
            if c > -20, c < 150 { values.append(c) }
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - Runtime

final class IOReportRuntime: @unchecked Sendable {
    static let shared = IOReportRuntime()

    private(set) var isReady = false

    #if canImport(Darwin)
    private let lock = NSLock()
    private var prepared = false
    private var handle: UnsafeMutableRawPointer?

    private typealias CopyChannelsFn = @convention(c) (
        CFString?, CFString?, UInt64, UInt64, UInt64
    ) -> Unmanaged<CFDictionary>?
    private typealias CreateSubscriptionFn = @convention(c) (
        UnsafeMutableRawPointer?,
        CFMutableDictionary?,
        UnsafeMutablePointer<Unmanaged<CFMutableDictionary>?>?,
        UInt64,
        CFTypeRef?
    ) -> Unmanaged<CFMutableDictionary>?
    private typealias CreateSamplesFn = @convention(c) (
        CFMutableDictionary?, CFMutableDictionary?, UnsafeMutableRawPointer?
    ) -> Unmanaged<CFDictionary>?
    private typealias ChannelNameFn = @convention(c) (CFDictionary?) -> Unmanaged<CFString>?
    private typealias SimpleValueFn = @convention(c) (CFDictionary?, UnsafeMutablePointer<UInt32>?) -> Int64
    private typealias IterateFn = @convention(c) (
        CFDictionary?,
        @convention(c) (CFDictionary?, UnsafeMutableRawPointer?) -> Int32,
        UnsafeMutableRawPointer?
    ) -> Void

    private var copyChannels: CopyChannelsFn?
    private var createSubscription: CreateSubscriptionFn?
    private var createSamples: CreateSamplesFn?
    private var channelName: ChannelNameFn?
    private var simpleValue: SimpleValueFn?
    private var iterate: IterateFn?

    private struct Subscription {
        let group: String
        let channels: CFMutableDictionary
        let subscription: CFMutableDictionary
    }

    private var subscriptions: [Subscription] = []
    #endif

    private init() {}

    func ensurePrepared() {
        #if canImport(Darwin)
        lock.lock()
        defer { lock.unlock() }
        guard !prepared else { return }
        prepared = true
        loadFramework()
        #endif
    }

    /// Samples one named group, or every non–Energy Model group when `named` is nil.
    func sampleSubscribed(named group: String?) -> [String: Int64] {
        #if canImport(Darwin)
        ensurePrepared()
        guard isReady, let createSamples, let iterate else { return [:] }

        lock.lock()
        let targets: [Subscription]
        if let group {
            targets = subscriptions.filter { $0.group == group }
        } else {
            targets = subscriptions.filter { $0.group != "Energy Model" }
        }
        lock.unlock()

        var merged: [String: Int64] = [:]
        for target in targets {
            guard let sample = createSamples(target.subscription, target.channels, nil)?.takeRetainedValue() else {
                continue
            }
            var bag = ValueBag()
            withUnsafeMutablePointer(to: &bag) { ptr in
                iterate(sample, { channel, raw -> Int32 in
                    guard let channel, let raw else { return 0 }
                    return IOReportRuntime.shared.appendChannel(channel, into: raw.assumingMemoryBound(to: ValueBag.self))
                }, UnsafeMutableRawPointer(ptr))
            }
            for (k, v) in bag.values { merged[k] = v }
        }
        return merged
        #else
        return [:]
        #endif
    }

    #if canImport(Darwin)
    private func loadFramework() {
        for path in [
            "/System/Library/PrivateFrameworks/IOReport.framework/IOReport",
            "/usr/lib/libIOReport.dylib"
        ] {
            if let h = dlopen(path, RTLD_LAZY) {
                handle = h
                break
            }
        }
        guard let handle else { return }

        func sym<T>(_ name: String) -> T? {
            guard let p = dlsym(handle, name) else { return nil }
            return unsafeBitCast(p, to: T.self)
        }

        copyChannels = sym("IOReportCopyChannelsInGroup")
        createSubscription = sym("IOReportCreateSubscription")
        createSamples = sym("IOReportCreateSamples")
        channelName = sym("IOReportChannelGetChannelName")
        simpleValue = sym("IOReportSimpleGetIntegerValue")
        iterate = sym("IOReportIterate")

        guard copyChannels != nil, createSubscription != nil, createSamples != nil,
              channelName != nil, simpleValue != nil, iterate != nil
        else { return }

        for group in ["Energy Model", "CPU Stats", "GPU Stats", "CLPC Stats", "PMP"] {
            if let sub = makeSubscription(group: group) {
                subscriptions.append(sub)
            }
        }
        isReady = !subscriptions.isEmpty
    }

    private func makeSubscription(group: String) -> Subscription? {
        guard let copyChannels, let createSubscription else { return nil }
        guard let copied = copyChannels(group as CFString, nil, 0, 0, 0)?.takeRetainedValue() else {
            return nil
        }
        guard let ns = (copied as NSDictionary).mutableCopy() as? NSMutableDictionary else {
            return nil
        }
        let channels = unsafeBitCast(ns as AnyObject, to: CFMutableDictionary.self)
        var unused: Unmanaged<CFMutableDictionary>?
        guard let sub = createSubscription(nil, channels, &unused, 0, nil)?.takeRetainedValue() else {
            return nil
        }
        return Subscription(group: group, channels: channels, subscription: sub)
    }

    fileprivate func appendChannel(
        _ channel: CFDictionary,
        into bag: UnsafeMutablePointer<ValueBag>
    ) -> Int32 {
        guard let channelName, let simpleValue else { return 0 }
        let name = channelName(channel)?.takeUnretainedValue() as String? ?? ""
        var flags: UInt32 = 0
        let value = simpleValue(channel, &flags)
        if !name.isEmpty {
            bag.pointee.values[name] = value
        }
        return 0
    }

    fileprivate struct ValueBag {
        var values: [String: Int64] = [:]
    }
    #endif
}
