import XCTest
@testable import SiliconStats

final class PerformanceSnapshotTests: XCTestCase {
    func testEmptyHasAllNils() {
        let s = PerformanceSnapshot.empty
        XCTAssertNil(s.cpuTemperatureCelsius)
        XCTAssertNil(s.cpuPowerWatts)
        XCTAssertNil(s.gpuTemperatureCelsius)
        XCTAssertNil(s.gpuPowerWatts)
        XCTAssertNil(s.framesPerSecond)
    }

    func testMergingPrefersIncomingNonNil() {
        let base = PerformanceSnapshot(cpuTemperatureCelsius: 40, cpuPowerWatts: 10)
        let other = PerformanceSnapshot(cpuPowerWatts: 76, gpuTemperatureCelsius: 65, framesPerSecond: 66)
        let merged = base.merging(other)
        XCTAssertEqual(merged.cpuTemperatureCelsius, 40)
        XCTAssertEqual(merged.cpuPowerWatts, 76)
        XCTAssertEqual(merged.gpuTemperatureCelsius, 65)
        XCTAssertEqual(merged.framesPerSecond, 66)
    }

    func testMergingDoesNotInventValues() {
        let merged = PerformanceSnapshot().merging(PerformanceSnapshot())
        XCTAssertNil(merged.cpuTemperatureCelsius)
        XCTAssertNil(merged.gpuPowerWatts)
        XCTAssertNil(merged.framesPerSecond)
    }

    func testMergingPerCoreAndMemoryBreakdown() {
        let base = PerformanceSnapshot(memoryUsedBytes: 1)
        let other = PerformanceSnapshot(
            perCoreCPUUtilizationPercent: [10, 20],
            memoryCachedBytes: 2,
            memoryFreeBytes: 3
        )
        let merged = base.merging(other)
        XCTAssertEqual(merged.perCoreCPUUtilizationPercent, [10, 20])
        XCTAssertEqual(merged.memoryUsedBytes, 1)
        XCTAssertEqual(merged.memoryCachedBytes, 2)
        XCTAssertEqual(merged.memoryFreeBytes, 3)
    }
}
