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
    /// Show `--` placeholders.
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
    public var showPerCoreCPU: Bool
    public var showGPUTemperature: Bool
    public var showGPUPower: Bool
    public var showGPUUtilization: Bool
    public var showMemory: Bool
    public var showMemoryBreakdown: Bool
    public var showFPS: Bool
    public var unavailableDisplay: UnavailableMetricDisplay

    /// Attempt private IOReport °C / W sampling (best-effort; still returns nil when channels fail).
    public var enablePrivateSensors: Bool

    // Appearance
    public var overlayOpacity: Double
    public var overlayPosition: OverlayPosition
    public var overlayScale: Double
    public var temperatureUnit: TemperatureUnit
    public var screenEdgePadding: Double

    /// Bumped when default metric visibility changes so existing installs migrate once.
    public var settingsSchemaVersion: Int

    public static let currentSchemaVersion = 3

    public static let `default` = AppSettings(
        showOverlay: true,
        launchAtLogin: false,
        showDockIcon: false,
        clickThrough: false,
        telemetryIntervalMilliseconds: 1000,
        // Public Mach CPU % / memory are real; private IOReport °C/W stay off until user enables.
        showCPUTemperature: false,
        showCPUPower: false,
        showCPUUtilization: true,
        showPerCoreCPU: true,
        showGPUTemperature: false,
        showGPUPower: false,
        showGPUUtilization: false,
        showMemory: true,
        showMemoryBreakdown: true,
        showFPS: true,
        unavailableDisplay: .hide,
        enablePrivateSensors: false,
        overlayOpacity: 0.88,
        overlayPosition: .topLeading,
        overlayScale: 1.0,
        temperatureUnit: .celsius,
        screenEdgePadding: 16,
        settingsSchemaVersion: currentSchemaVersion
    )

    enum CodingKeys: String, CodingKey {
        case showOverlay, launchAtLogin, showDockIcon, clickThrough, telemetryIntervalMilliseconds
        case showCPUTemperature, showCPUPower, showCPUUtilization, showPerCoreCPU
        case showGPUTemperature, showGPUPower, showGPUUtilization
        case showMemory, showMemoryBreakdown, showFPS, unavailableDisplay
        case enablePrivateSensors
        case overlayOpacity, overlayPosition, overlayScale, temperatureUnit, screenEdgePadding
        case settingsSchemaVersion
    }

    public init(
        showOverlay: Bool,
        launchAtLogin: Bool,
        showDockIcon: Bool,
        clickThrough: Bool,
        telemetryIntervalMilliseconds: Int,
        showCPUTemperature: Bool,
        showCPUPower: Bool,
        showCPUUtilization: Bool,
        showPerCoreCPU: Bool,
        showGPUTemperature: Bool,
        showGPUPower: Bool,
        showGPUUtilization: Bool,
        showMemory: Bool,
        showMemoryBreakdown: Bool,
        showFPS: Bool,
        unavailableDisplay: UnavailableMetricDisplay,
        enablePrivateSensors: Bool,
        overlayOpacity: Double,
        overlayPosition: OverlayPosition,
        overlayScale: Double,
        temperatureUnit: TemperatureUnit,
        screenEdgePadding: Double,
        settingsSchemaVersion: Int
    ) {
        self.showOverlay = showOverlay
        self.launchAtLogin = launchAtLogin
        self.showDockIcon = showDockIcon
        self.clickThrough = clickThrough
        self.telemetryIntervalMilliseconds = telemetryIntervalMilliseconds
        self.showCPUTemperature = showCPUTemperature
        self.showCPUPower = showCPUPower
        self.showCPUUtilization = showCPUUtilization
        self.showPerCoreCPU = showPerCoreCPU
        self.showGPUTemperature = showGPUTemperature
        self.showGPUPower = showGPUPower
        self.showGPUUtilization = showGPUUtilization
        self.showMemory = showMemory
        self.showMemoryBreakdown = showMemoryBreakdown
        self.showFPS = showFPS
        self.unavailableDisplay = unavailableDisplay
        self.enablePrivateSensors = enablePrivateSensors
        self.overlayOpacity = overlayOpacity
        self.overlayPosition = overlayPosition
        self.overlayScale = overlayScale
        self.temperatureUnit = temperatureUnit
        self.screenEdgePadding = screenEdgePadding
        self.settingsSchemaVersion = settingsSchemaVersion
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showOverlay = try container.decodeIfPresent(Bool.self, forKey: .showOverlay) ?? true
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        showDockIcon = try container.decodeIfPresent(Bool.self, forKey: .showDockIcon) ?? false
        clickThrough = try container.decodeIfPresent(Bool.self, forKey: .clickThrough) ?? false
        telemetryIntervalMilliseconds = try container.decodeIfPresent(Int.self, forKey: .telemetryIntervalMilliseconds) ?? 1000
        showCPUTemperature = try container.decodeIfPresent(Bool.self, forKey: .showCPUTemperature) ?? false
        showCPUPower = try container.decodeIfPresent(Bool.self, forKey: .showCPUPower) ?? false
        showCPUUtilization = try container.decodeIfPresent(Bool.self, forKey: .showCPUUtilization) ?? true
        showPerCoreCPU = try container.decodeIfPresent(Bool.self, forKey: .showPerCoreCPU) ?? true
        showGPUTemperature = try container.decodeIfPresent(Bool.self, forKey: .showGPUTemperature) ?? false
        showGPUPower = try container.decodeIfPresent(Bool.self, forKey: .showGPUPower) ?? false
        showGPUUtilization = try container.decodeIfPresent(Bool.self, forKey: .showGPUUtilization) ?? false
        showMemory = try container.decodeIfPresent(Bool.self, forKey: .showMemory) ?? true
        showMemoryBreakdown = try container.decodeIfPresent(Bool.self, forKey: .showMemoryBreakdown) ?? true
        showFPS = try container.decodeIfPresent(Bool.self, forKey: .showFPS) ?? true
        unavailableDisplay = try container.decodeIfPresent(UnavailableMetricDisplay.self, forKey: .unavailableDisplay) ?? .hide
        enablePrivateSensors = try container.decodeIfPresent(Bool.self, forKey: .enablePrivateSensors) ?? false
        overlayOpacity = try container.decodeIfPresent(Double.self, forKey: .overlayOpacity) ?? 0.88
        overlayPosition = try container.decodeIfPresent(OverlayPosition.self, forKey: .overlayPosition) ?? .topLeading
        overlayScale = try container.decodeIfPresent(Double.self, forKey: .overlayScale) ?? 1.0
        temperatureUnit = try container.decodeIfPresent(TemperatureUnit.self, forKey: .temperatureUnit) ?? .celsius
        screenEdgePadding = try container.decodeIfPresent(Double.self, forKey: .screenEdgePadding) ?? 16
        settingsSchemaVersion = try container.decodeIfPresent(Int.self, forKey: .settingsSchemaVersion) ?? 1
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showOverlay, forKey: .showOverlay)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(showDockIcon, forKey: .showDockIcon)
        try container.encode(clickThrough, forKey: .clickThrough)
        try container.encode(telemetryIntervalMilliseconds, forKey: .telemetryIntervalMilliseconds)
        try container.encode(showCPUTemperature, forKey: .showCPUTemperature)
        try container.encode(showCPUPower, forKey: .showCPUPower)
        try container.encode(showCPUUtilization, forKey: .showCPUUtilization)
        try container.encode(showPerCoreCPU, forKey: .showPerCoreCPU)
        try container.encode(showGPUTemperature, forKey: .showGPUTemperature)
        try container.encode(showGPUPower, forKey: .showGPUPower)
        try container.encode(showGPUUtilization, forKey: .showGPUUtilization)
        try container.encode(showMemory, forKey: .showMemory)
        try container.encode(showMemoryBreakdown, forKey: .showMemoryBreakdown)
        try container.encode(showFPS, forKey: .showFPS)
        try container.encode(unavailableDisplay, forKey: .unavailableDisplay)
        try container.encode(enablePrivateSensors, forKey: .enablePrivateSensors)
        try container.encode(overlayOpacity, forKey: .overlayOpacity)
        try container.encode(overlayPosition, forKey: .overlayPosition)
        try container.encode(overlayScale, forKey: .overlayScale)
        try container.encode(temperatureUnit, forKey: .temperatureUnit)
        try container.encode(screenEdgePadding, forKey: .screenEdgePadding)
        try container.encode(settingsSchemaVersion, forKey: .settingsSchemaVersion)
    }

    /// Incremental migrations: v2 Mach defaults, v3 per-core + memory breakdown.
    public mutating func migrateIfNeeded() {
        guard settingsSchemaVersion < AppSettings.currentSchemaVersion else { return }
        if settingsSchemaVersion < 2 {
            showCPUUtilization = true
            showMemory = true
            showCPUTemperature = false
            showCPUPower = false
            showGPUTemperature = false
            showGPUPower = false
            showGPUUtilization = false
            unavailableDisplay = .hide
        }
        if settingsSchemaVersion < 3 {
            showPerCoreCPU = true
            showMemoryBreakdown = true
        }
        settingsSchemaVersion = AppSettings.currentSchemaVersion
    }
}
