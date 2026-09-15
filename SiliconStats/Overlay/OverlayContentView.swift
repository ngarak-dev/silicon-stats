import SwiftUI

/// Colors matching `media/overlay-reference.png`.
public enum OverlayPalette {
    public static let cpuLabel = Color(red: 0.35, green: 0.62, blue: 0.95)      // blue
    public static let gpuLabel = Color(red: 0.72, green: 0.82, blue: 0.86)      // cyan-gray
    public static let memLabel = Color(red: 0.78, green: 0.72, blue: 0.92)      // soft violet
    public static let fpsLabel = Color(red: 0.40, green: 0.86, blue: 0.62)      // mint green
    public static let value = Color.white
    public static let pillFill = Color.black
}

/// Single metric cluster: colored label + white values (e.g. `CPU 42%`).
public struct MetricGroupView: View {
    public let label: String
    public let labelColor: Color
    public let values: [String]
    public let scale: CGFloat

    public init(label: String, labelColor: Color, values: [String], scale: CGFloat = 1) {
        self.label = label
        self.labelColor = labelColor
        self.values = values
        self.scale = scale
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6 * scale) {
            Text(label)
                .font(.system(size: 13 * scale, weight: .semibold, design: .rounded))
                .foregroundStyle(labelColor)

            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                valueText(value)
            }
        }
    }

    @ViewBuilder
    private func valueText(_ raw: String) -> some View {
        // Slightly smaller unit suffixes for W / % / GB / °C / °F.
        if raw.hasSuffix("W"), raw.count > 1, raw != MetricFormatter.unavailablePlaceholder {
            mixedUnit(String(raw.dropLast()), unit: "W")
        } else if raw.hasSuffix("%"), raw.count > 1, raw != MetricFormatter.unavailablePlaceholder {
            mixedUnit(String(raw.dropLast()), unit: "%")
        } else if raw.hasSuffix("GB"), raw.count > 2, raw != MetricFormatter.unavailablePlaceholder {
            mixedUnit(String(raw.dropLast(2)), unit: "GB")
        } else if raw.hasSuffix("°C") || raw.hasSuffix("°F") {
            Text(raw)
                .font(.system(size: 13 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(OverlayPalette.value)
        } else {
            Text(raw)
                .font(.system(size: 13 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(OverlayPalette.value)
        }
    }

    private func mixedUnit(_ number: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(number)
                .font(.system(size: 13 * scale, weight: .medium, design: .rounded))
            Text(unit)
                .font(.system(size: 10 * scale, weight: .medium, design: .rounded))
        }
        .foregroundStyle(OverlayPalette.value)
    }
}

/// Horizontal black pill HUD: CPU · MEM · GPU · FPS (groups hide when empty).
public struct OverlayContentView: View {
    public let snapshot: PerformanceSnapshot
    public let settings: AppSettings

    public init(snapshot: PerformanceSnapshot, settings: AppSettings) {
        self.snapshot = snapshot
        self.settings = settings
    }

    public var body: some View {
        HStack(spacing: 18 * settings.overlayScale) {
            if showCPU {
                MetricGroupView(
                    label: "CPU",
                    labelColor: OverlayPalette.cpuLabel,
                    values: cpuValues,
                    scale: settings.overlayScale
                )
            }
            if showMemory {
                MetricGroupView(
                    label: "MEM",
                    labelColor: OverlayPalette.memLabel,
                    values: memoryValues,
                    scale: settings.overlayScale
                )
            }
            if showGPU {
                MetricGroupView(
                    label: "GPU",
                    labelColor: OverlayPalette.gpuLabel,
                    values: gpuValues,
                    scale: settings.overlayScale
                )
            }
            if showFPS {
                MetricGroupView(
                    label: "FPS",
                    labelColor: OverlayPalette.fpsLabel,
                    values: [MetricFormatter.framesPerSecond(snapshot.framesPerSecond)],
                    scale: settings.overlayScale
                )
            }
        }
        .padding(.horizontal, 16 * settings.overlayScale)
        .padding(.vertical, 8 * settings.overlayScale)
        .background(
            Capsule(style: .continuous)
                .fill(OverlayPalette.pillFill.opacity(settings.overlayOpacity))
        )
    }

    private var showCPU: Bool {
        guard settings.showCPUTemperature || settings.showCPUPower || settings.showCPUUtilization else {
            return false
        }
        if settings.unavailableDisplay == .hide,
           cpuValues.allSatisfy({ $0 == MetricFormatter.unavailablePlaceholder }) {
            return false
        }
        return true
    }

    private var showMemory: Bool {
        guard settings.showMemory else { return false }
        if settings.unavailableDisplay == .hide,
           memoryValues.allSatisfy({ $0 == MetricFormatter.unavailablePlaceholder }) {
            return false
        }
        return true
    }

    private var showGPU: Bool {
        guard settings.showGPUTemperature || settings.showGPUPower || settings.showGPUUtilization else {
            return false
        }
        if settings.unavailableDisplay == .hide,
           gpuValues.allSatisfy({ $0 == MetricFormatter.unavailablePlaceholder }) {
            return false
        }
        return true
    }

    private var showFPS: Bool {
        guard settings.showFPS else { return false }
        if settings.unavailableDisplay == .hide, snapshot.framesPerSecond == nil {
            return false
        }
        return true
    }

    private var cpuValues: [String] {
        var parts: [String] = []
        if settings.showCPUTemperature {
            parts.append(
                MetricFormatter.temperature(
                    celsius: snapshot.cpuTemperatureCelsius,
                    unit: settings.temperatureUnit
                )
            )
        }
        if settings.showCPUPower {
            parts.append(MetricFormatter.powerWatts(snapshot.cpuPowerWatts))
        }
        if settings.showCPUUtilization {
            parts.append(MetricFormatter.utilizationPercent(snapshot.cpuUtilizationPercent))
        }
        return parts
    }

    private var memoryValues: [String] {
        [MetricFormatter.memoryUsedGigabytes(usedBytes: snapshot.memoryUsedBytes)]
    }

    private var gpuValues: [String] {
        var parts: [String] = []
        if settings.showGPUTemperature {
            parts.append(
                MetricFormatter.temperature(
                    celsius: snapshot.gpuTemperatureCelsius,
                    unit: settings.temperatureUnit
                )
            )
        }
        if settings.showGPUPower {
            parts.append(MetricFormatter.powerWatts(snapshot.gpuPowerWatts))
        }
        if settings.showGPUUtilization {
            parts.append(MetricFormatter.utilizationPercent(snapshot.gpuUtilizationPercent))
        }
        return parts
    }
}

#Preview("HUD Live Defaults") {
    OverlayContentView(
        snapshot: PerformanceSnapshot(
            cpuUtilizationPercent: 42,
            memoryUsedBytes: 18_000_000_000,
            memoryTotalBytes: 36_000_000_000,
            framesPerSecond: 120
        ),
        settings: .default
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

#Preview("HUD Reference Temps") {
    OverlayContentView(
        snapshot: PerformanceSnapshot(
            cpuTemperatureCelsius: 71,
            cpuPowerWatts: 76,
            gpuTemperatureCelsius: 65,
            gpuPowerWatts: 299,
            framesPerSecond: 66
        ),
        settings: {
            var s = AppSettings.default
            s.showCPUTemperature = true
            s.showCPUPower = true
            s.showCPUUtilization = false
            s.showGPUTemperature = true
            s.showGPUPower = true
            s.showMemory = false
            s.unavailableDisplay = .placeholder
            return s
        }()
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}
