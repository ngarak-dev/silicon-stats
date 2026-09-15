import Foundation

public enum TemperatureUnit: String, CaseIterable, Codable, Sendable {
    case celsius
    case fahrenheit

    public var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }

    public var displayName: String {
        switch self {
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        }
    }
}

public enum OverlayPosition: String, CaseIterable, Codable, Sendable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    public var displayName: String {
        switch self {
        case .topLeading: return "Top Left"
        case .topTrailing: return "Top Right"
        case .bottomLeading: return "Bottom Left"
        case .bottomTrailing: return "Bottom Right"
        }
    }
}

public enum UnavailableMetricDisplay: String, CaseIterable, Codable, Sendable {
    /// Show `--` placeholders (default, matches reference HUD).
    case placeholder
    /// Hide the metric group entirely when all of its values are nil.
    case hide
}

/// User-configurable preferences persisted via `UserDefaults`.
public struct AppSettings: Equatable, Codable, Sendable {
    // General
    public var showOverlay: Bool
    public var launchAtLogin: Bool
    public var showDockIcon: Bool
    public var clickThrough: Bool
    public var telemetryIntervalMilliseconds: Int

    // Metrics visibility
    public var showCPUTemperature: Bool
    public var showCPUPower: Bool
    public var showCPUUtilization: Bool
    public var showGPUTemperature: Bool
    public var showGPUPower: Bool
    public var showGPUUtilization: Bool
    public var showFPS: Bool
    public var unavailableDisplay: UnavailableMetricDisplay

    // Appearance
    public var overlayOpacity: Double
    public var overlayPosition: OverlayPosition
    public var overlayScale: Double
    public var temperatureUnit: TemperatureUnit
    public var screenEdgePadding: Double

    public static let `default` = AppSettings(
        showOverlay: true,
        launchAtLogin: false,
        showDockIcon: false,
        clickThrough: false,
        telemetryIntervalMilliseconds: 1000,
        showCPUTemperature: true,
        showCPUPower: true,
        showCPUUtilization: false,
        showGPUTemperature: true,
        showGPUPower: true,
        showGPUUtilization: false,
        showFPS: true,
        unavailableDisplay: .placeholder,
        overlayOpacity: 0.88,
        overlayPosition: .topLeading,
        overlayScale: 1.0,
        temperatureUnit: .celsius,
        screenEdgePadding: 16
    )
}
