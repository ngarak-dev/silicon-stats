import XCTest
@testable import SiliconStats

final class IOReportProviderTests: XCTestCase {
    func testDisabledProviderNeverFabricatesMetrics() {
        let provider = IOReportTelemetryProvider(isEnabled: false)
        let sample = provider.sample()
        XCTAssertNil(sample.cpuTemperatureCelsius)
        XCTAssertNil(sample.cpuPowerWatts)
        XCTAssertNil(sample.gpuTemperatureCelsius)
        XCTAssertNil(sample.gpuPowerWatts)
        XCTAssertNil(sample.framesPerSecond)
    }

    func testEnabledWithoutChannelMapStillReturnsNil() {
        let provider = IOReportTelemetryProvider(isEnabled: true)
        let sample = provider.sample()
        XCTAssertNil(sample.cpuTemperatureCelsius)
        XCTAssertNil(sample.gpuPowerWatts)
    }

    func testScreenCaptureFPSStub() {
        let fps = ScreenCaptureFPSProvider()
        XCTAssertEqual(fps.status, .stubbed)
        XCTAssertNil(fps.currentFPS())
    }
}
