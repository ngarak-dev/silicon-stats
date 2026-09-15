import Foundation

/// Formats optional metric values for the HUD. Never invents numbers —
/// missing values become `--` (or an empty string when callers hide the field).
public enum MetricFormatter {
    public static let unavailablePlaceholder = "--"

    private static let temperatureNumber: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        f.roundingMode = .halfUp
        return f
    }()

    private static let powerNumber: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        f.roundingMode = .halfUp
        return f
    }()

    private static let utilizationNumber: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        f.roundingMode = .halfUp
        return f
    }()

    private static let fpsNumber: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        f.roundingMode = .halfUp
        return f
    }()

    public static func temperature(
        celsius: Double?,
        unit: TemperatureUnit,
        includeUnit: Bool = true
    ) -> String {
        guard let celsius else { return unavailablePlaceholder }
        let value = UnitConversion.celsius(celsius, to: unit)
        let number = temperatureNumber.string(from: NSNumber(value: value)) ?? unavailablePlaceholder
        return includeUnit ? "\(number)\(unit.symbol)" : number
    }

    public static func powerWatts(_ watts: Double?, includeUnit: Bool = true) -> String {
        guard let watts else { return unavailablePlaceholder }
        let number = powerNumber.string(from: NSNumber(value: watts)) ?? unavailablePlaceholder
        return includeUnit ? "\(number)W" : number
    }

    public static func utilizationPercent(_ percent: Double?, includeUnit: Bool = true) -> String {
        guard let percent else { return unavailablePlaceholder }
        let clamped = min(max(percent, 0), 100)
        let number = utilizationNumber.string(from: NSNumber(value: clamped)) ?? unavailablePlaceholder
        return includeUnit ? "\(number)%" : number
    }

    public static func framesPerSecond(_ fps: Double?) -> String {
        guard let fps, fps.isFinite, fps >= 0 else { return unavailablePlaceholder }
        return fpsNumber.string(from: NSNumber(value: fps)) ?? unavailablePlaceholder
    }

    /// Splits a power string into numeric body + unit suffix for mixed-size typography.
    public static func powerParts(_ watts: Double?) -> (value: String, unit: String) {
        guard watts != nil else { return (unavailablePlaceholder, "") }
        let full = powerWatts(watts, includeUnit: true)
        if full.hasSuffix("W") {
            return (String(full.dropLast()), "W")
        }
        return (full, "")
    }

    public static func temperatureParts(
        celsius: Double?,
        unit: TemperatureUnit
    ) -> (value: String, unit: String) {
        guard celsius != nil else { return (unavailablePlaceholder, "") }
        let full = temperature(celsius: celsius, unit: unit, includeUnit: true)
        let symbol = unit.symbol
        if full.hasSuffix(symbol) {
            return (String(full.dropLast(symbol.count)), symbol)
        }
        return (full, "")
    }
}
