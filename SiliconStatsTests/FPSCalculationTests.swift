import XCTest
@testable import SiliconStats

final class FPSCalculationTests: XCTestCase {
    func testFPSFromTimestamps() {
        let timestamps: [CFTimeInterval] = [0, 0.5, 1.0]
        let fps = FPSCalculator.framesPerSecond(timestamps: timestamps)
        XCTAssertEqual(fps!, 2.0, accuracy: 0.001)
    }

    func testFPSRequiresTwoSamples() {
        XCTAssertNil(FPSCalculator.framesPerSecond(timestamps: []))
        XCTAssertNil(FPSCalculator.framesPerSecond(timestamps: [1.0]))
    }

    func testFPSRejectsNonIncreasing() {
        XCTAssertNil(FPSCalculator.framesPerSecond(timestamps: [1.0, 1.0]))
        XCTAssertNil(FPSCalculator.framesPerSecond(timestamps: [2.0, 1.0]))
    }

    func testSmoothEMA() {
        XCTAssertEqual(FPSCalculator.smooth(previous: nil, sample: 60), 60)
        let smoothed = FPSCalculator.smooth(previous: 60, sample: 40, alpha: 0.5)
        XCTAssertEqual(smoothed, 50, accuracy: 0.001)
    }

    func testSixtyFPSCadence() {
        var stamps: [CFTimeInterval] = []
        for i in 0..<61 {
            stamps.append(CFTimeInterval(i) / 60.0)
        }
        let fps = FPSCalculator.framesPerSecond(timestamps: stamps)!
        XCTAssertEqual(fps, 60.0, accuracy: 0.01)
    }
}
