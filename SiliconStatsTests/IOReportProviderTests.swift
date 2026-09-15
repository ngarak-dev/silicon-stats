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
        XCTAssertNil(sample.packagePowerWatts)
        XCTAssertNil(sample.framesPerSecond)
        XCTAssertEqual(provider.availability.cpuTemperature, .disabled)
    }

    func testEnabledWithoutReadableChannelsStillReturnsNil() {
        // On Linux / without IOReport.framework this stays nil — never invents °C/W.
        let provider = IOReportTelemetryProvider(isEnabled: true)
        let sample = provider.sample()
        XCTAssertNil(sample.cpuTemperatureCelsius)
        XCTAssertNil(sample.cpuPowerWatts)
        XCTAssertNil(sample.gpuTemperatureCelsius)
        XCTAssertNil(sample.gpuPowerWatts)
        XCTAssertNil(sample.packagePowerWatts)
        XCTAssertEqual(provider.availability.cpuPower, .requiresPrivateAPI)
    }

    func testScreenCaptureFPSStub() {
        let fps = ScreenCaptureFPSProvider()
        XCTAssertEqual(fps.status, .stubbed)
        XCTAssertNil(fps.currentFPS())
    }
}
