import SwiftUI

public struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    let availability: MetricAvailability

    public init(store: SettingsStore, availability: MetricAvailability) {
        self.store = store
        self.availability = availability
    }

    public var body: some View {
        TabView {
            GeneralSettingsView(store: store)
                .tabItem { Label("General", systemImage: "gearshape") }
            MetricsSettingsView(store: store, availability: availability)
                .tabItem { Label("Metrics", systemImage: "gauge.with.dots.needle.33percent") }
            AppearanceSettingsView(store: store)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 420, height: 360)
        .padding(.top, 8)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            Toggle("Show overlay", isOn: binding(\.showOverlay))
            Toggle("Click-through overlay", isOn: binding(\.clickThrough))
            Toggle("Show Dock icon", isOn: Binding(
                get: { store.settings.showDockIcon },
                set: { newValue in
                    store.update { $0.showDockIcon = newValue }
                    store.applyDockIconPreference()
                }
            ))
            Toggle("Launch at login", isOn: Binding(
                get: { store.settings.launchAtLogin },
                set: { newValue in
                    store.update { $0.launchAtLogin = newValue }
                    store.applyLaunchAtLogin()
                }
            ))
            Stepper(
                value: binding(\.telemetryIntervalMilliseconds),
                in: 250...5000,
                step: 250
            ) {
                Text("Refresh interval: \(store.settings.telemetryIntervalMilliseconds) ms")
            }
            Button("Reset All Settings") {
                store.resetToDefaults()
                store.applyDockIconPreference()
            }
        }
        .padding()
    }

    private func binding<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { newValue in store.update { $0[keyPath: keyPath] = newValue } }
        )
    }
}

struct MetricsSettingsView: View {
    @ObservedObject var store: SettingsStore
    let availability: MetricAvailability

    var body: some View {
        Form {
            Section("CPU") {
                Toggle("Temperature", isOn: binding(\.showCPUTemperature))
                statusRow("Temp source", availability.cpuTemperature)
                Toggle("Power", isOn: binding(\.showCPUPower))
                statusRow("Power source", availability.cpuPower)
                Toggle("Utilization %", isOn: binding(\.showCPUUtilization))
                statusRow("Utilization source", availability.cpuUtilization)
            }
            Section("GPU") {
                Toggle("Temperature", isOn: binding(\.showGPUTemperature))
                statusRow("Temp source", availability.gpuTemperature)
                Toggle("Power", isOn: binding(\.showGPUPower))
                statusRow("Power source", availability.gpuPower)
                Toggle("Utilization %", isOn: binding(\.showGPUUtilization))
            }
            Section("Memory") {
                Toggle("Show memory used", isOn: binding(\.showMemory))
                statusRow("Memory source", availability.memory)
            }
            Section("FPS") {
                Toggle("Show FPS", isOn: binding(\.showFPS))
                statusRow("FPS source", availability.framesPerSecond)
            }
            Section("Unavailable metrics") {
                Picker("When missing", selection: binding(\.unavailableDisplay)) {
                    ForEach(UnavailableMetricDisplay.allCases, id: \.self) { mode in
                        Text(mode == .placeholder ? "Show --" : "Hide").tag(mode)
                    }
                }
            }
            Text("Private IOReport channels are off until validated on Apple Silicon. See Docs/TELEMETRY.md.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func statusRow(_ title: String, _ status: MetricSourceStatus) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(status.rawValue)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { newValue in store.update { $0[keyPath: keyPath] = newValue } }
        )
    }
}

struct AppearanceSettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            Picker("Position", selection: binding(\.overlayPosition)) {
                ForEach(OverlayPosition.allCases, id: \.self) { position in
                    Text(position.displayName).tag(position)
                }
            }
            Picker("Temperature unit", selection: binding(\.temperatureUnit)) {
                ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            HStack {
                Text("Opacity")
                Slider(value: binding(\.overlayOpacity), in: 0.5...1.0, step: 0.01)
                Text("\(Int(store.settings.overlayOpacity * 100))%")
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }
            HStack {
                Text("Scale")
                Slider(value: binding(\.overlayScale), in: 0.8...1.6, step: 0.05)
                Text(String(format: "%.2f×", store.settings.overlayScale))
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            }
            Stepper(value: binding(\.screenEdgePadding), in: 4...48, step: 2) {
                Text("Edge padding: \(Int(store.settings.screenEdgePadding)) pt")
            }
        }
        .padding()
    }

    private func binding<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { newValue in store.update { $0[keyPath: keyPath] = newValue } }
        )
    }
}
