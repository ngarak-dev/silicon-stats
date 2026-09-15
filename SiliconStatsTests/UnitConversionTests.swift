import XCTest
@testable import SiliconStats

final class UnitConversionTests: XCTestCase {
    func testCelsiusFahrenheitRoundTrip() {
        let c = 71.0
        let f = UnitConversion.celsiusToFahrenheit(c)
        XCTAssertEqual(f, 159.8, accuracy: 0.001)
        XCTAssertEqual(UnitConversion.fahrenheitToCelsius(f), c, accuracy: 0.001)
    }

    func testCelsiusToUnit() {
        XCTAssertEqual(UnitConversion.celsius(25, to: .celsius), 25)
        XCTAssertEqual(UnitConversion.celsius(0, to: .fahrenheit), 32)
    }

    func testPowerUnitScales() {
        XCTAssertEqual(UnitConversion.milliwattsToWatts(76_000), 76, accuracy: 0.001)
        XCTAssertEqual(UnitConversion.microwattsToWatts(76_000_000), 76, accuracy: 0.001)
    }

    func testBytesToGigabytes() {
        XCTAssertEqual(UnitConversion.bytesToGigabytes(1_073_741_824), 1.0, accuracy: 0.0001)
    }
}
