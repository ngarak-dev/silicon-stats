import Foundation

public enum UnitConversion {
    public static func celsiusToFahrenheit(_ celsius: Double) -> Double {
        celsius * 9.0 / 5.0 + 32.0
    }

    public static func fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        (fahrenheit - 32.0) * 5.0 / 9.0
    }

    public static func celsius(_ value: Double, to unit: TemperatureUnit) -> Double {
        switch unit {
        case .celsius: return value
        case .fahrenheit: return celsiusToFahrenheit(value)
        }
    }

    public static func milliwattsToWatts(_ milliwatts: Double) -> Double {
        milliwatts / 1000.0
    }

    public static func microwattsToWatts(_ microwatts: Double) -> Double {
        microwatts / 1_000_000.0
    }

    public static func bytesToGigabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / 1_073_741_824.0
    }
}
