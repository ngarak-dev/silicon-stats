import SwiftUI

/// Colors matching `media/overlay-reference.png`.
public enum OverlayPalette {
    public static let cpuLabel = Color(red: 0.35, green: 0.62, blue: 0.95)      // blue
    public static let gpuLabel = Color(red: 0.72, green: 0.82, blue: 0.86)      // cyan-gray
    public static let fpsLabel = Color(red: 0.40, green: 0.86, blue: 0.62)      // mint green
    public static let value = Color.white
    public static let pillFill = Color.black
}

/// Single metric cluster: colored label + white values (e.g. `CPU 71°C 76W`).
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
        // Slightly smaller unit suffixes for W / °C / °F to match the reference.
        if raw.hasSuffix("W"), raw.count > 1, raw != MetricFormatter.unavailablePlaceholder {
            let number = String(raw.dropLast())
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(number)
                    .font(.system(size: 13 * scale, weight: .medium, design: .rounded))
                Text("W")
                    .font(.system(size: 10 * scale, weight: .medium, design: .rounded))
            }
            .foregroundStyle(OverlayPalette.value)
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
}

/// Horizontal black pill HUD: CPU · GPU · FPS.
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
        let values = cpuValues
        if settings.unavailableDisplay == .hide,
           values.allSatisfy({ $0 == MetricFormatter.unavailablePlaceholder }) {
            return false
        }
        return settings.showCPUTemperature || settings.showCPUPower || settings.showCPUUtilization
    }

    private var showGPU: Bool {
        let values = gpuValues
        if settings.unavailableDisplay == .hide,
           values.allSatisfy({ $0 == MetricFormatter.unavailablePlaceholder }) {
            return false
        }
        return settings.showGPUTemperature || settings.showGPUPower || settings.showGPUUtilization
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

#Preview("HUD Reference") {
    OverlayContentView(
        snapshot: PerformanceSnapshot(
            cpuTemperatureCelsius: 71,
            cpuPowerWatts: 76,
            gpuTemperatureCelsius: 65,
            gpuPowerWatts: 299,
            framesPerSecond: 66
        ),
        settings: .default
    )
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

#Preview("Unavailable") {
    OverlayContentView(snapshot: .empty, settings: .default)
        .padding(40)
        .background(Color.gray.opacity(0.3))
}
