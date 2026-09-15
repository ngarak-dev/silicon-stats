import XCTest
@testable import SiliconStats

final class MetricFormatterTests: XCTestCase {
    func testTemperatureNilIsPlaceholder() {
        XCTAssertEqual(
            MetricFormatter.temperature(celsius: nil, unit: .celsius),
            MetricFormatter.unavailablePlaceholder
        )
    }

    func testTemperatureCelsiusFormatting() {
        XCTAssertEqual(MetricFormatter.temperature(celsius: 71.4, unit: .celsius), "71°C")
        XCTAssertEqual(MetricFormatter.temperature(celsius: 71.4, unit: .fahrenheit), "161°F")
    }

    func testPowerNilAndValue() {
        XCTAssertEqual(MetricFormatter.powerWatts(nil), "--")
        XCTAssertEqual(MetricFormatter.powerWatts(76.2), "76W")
        XCTAssertEqual(MetricFormatter.powerParts(299).value, "299")
        XCTAssertEqual(MetricFormatter.powerParts(299).unit, "W")
        XCTAssertEqual(MetricFormatter.powerParts(nil).value, "--")
    }

    func testUtilizationClamped() {
        XCTAssertEqual(MetricFormatter.utilizationPercent(nil), "--")
        XCTAssertEqual(MetricFormatter.utilizationPercent(55.6), "56%")
        XCTAssertEqual(MetricFormatter.utilizationPercent(150), "100%")
        XCTAssertEqual(MetricFormatter.utilizationPercent(-5), "0%")
    }

    func testFPSFormatting() {
        XCTAssertEqual(MetricFormatter.framesPerSecond(nil), "--")
        XCTAssertEqual(MetricFormatter.framesPerSecond(66.4), "66")
        XCTAssertEqual(MetricFormatter.framesPerSecond(.nan), "--")
        XCTAssertEqual(MetricFormatter.framesPerSecond(-1), "--")
    }

    func testMemoryFormatting() {
        XCTAssertEqual(MetricFormatter.memoryUsedGigabytes(usedBytes: nil), "--")
        XCTAssertEqual(MetricFormatter.memoryUsedGigabytes(usedBytes: 1_073_741_824), "1GB")
        XCTAssertEqual(MetricFormatter.memoryUsedGigabytes(usedBytes: 18_874_368_000), "17.6GB")
    }

    func testMemoryBreakdownLabeled() {
        let parts = MetricFormatter.memoryBreakdown(
            usedBytes: 1_073_741_824,
            cachedBytes: 2_147_483_648,
            freeBytes: 536_870_912
        )
        XCTAssertEqual(parts, ["U1GB", "C2GB", "F0.5GB"])
    }

    func testMemoryBreakdownAllNil() {
        XCTAssertEqual(
            MetricFormatter.memoryBreakdown(usedBytes: nil, cachedBytes: nil, freeBytes: nil),
            ["--"]
        )
    }
}
