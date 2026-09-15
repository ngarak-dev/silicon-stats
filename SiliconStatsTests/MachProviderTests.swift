import XCTest
@testable import SiliconStats

final class MachProviderTests: XCTestCase {
    func testCPULoadFirstSampleDoesNotInventUtilization() {
        let provider = CPULoadTelemetryProvider()
        let first = provider.sample()
        // First tick has no delta window — must stay nil, not 0% fiction.
        XCTAssertNil(first.cpuUtilizationPercent)
        XCTAssertNil(first.perCoreCPUUtilizationPercent)
        XCTAssertEqual(provider.availability.cpuUtilization, .available)
    }

    func testMemoryProviderOnNonDarwinReturnsEmpty() {
        let provider = MemoryTelemetryProvider()
        let sample = provider.sample()
        #if canImport(Darwin)
        // May succeed on macOS; if it does, all breakdown fields should be present together.
        if sample.memoryTotalBytes != nil {
            XCTAssertNotNil(sample.memoryUsedBytes)
            XCTAssertNotNil(sample.memoryCachedBytes)
            XCTAssertNotNil(sample.memoryFreeBytes)
        }
        #else
        XCTAssertNil(sample.memoryUsedBytes)
        XCTAssertNil(sample.memoryCachedBytes)
        XCTAssertNil(sample.memoryFreeBytes)
        XCTAssertNil(sample.memoryTotalBytes)
        #endif
    }
}
