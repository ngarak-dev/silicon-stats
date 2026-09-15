# Telemetry & FPS sources

Silicon Stats never fabricates sensor or FPS values. Missing data renders as `--` (or the metric group is hidden when configured).

This cloud/Linux environment cannot compile or validate macOS binaries. Treat hardware-dependent rows as **unverified** until exercised on Apple Silicon.

## Metric matrix

| Metric | Provider | API surface | Status in this build | Notes |
|---|---|---|---|---|
| CPU utilization % | `CPULoadTelemetryProvider` | Public Mach `host_statistics` / `HOST_CPU_LOAD_INFO` | **Implemented** (logic present; unverified on device in CI) | Idle/busy tick deltas |
| Memory used/total | `MemoryTelemetryProvider` | Public Mach `host_statistics64` / `HOST_VM_INFO64` | **Implemented** (unverified on device in CI) | Shown on pill as **MEM** by default |
| Thermal state | `ThermalStateTelemetryProvider` | Public `ProcessInfo.thermalState` | **Implemented** — qualitative only | Does **not** map to °C |
| CPU temperature °C | `IOReportTelemetryProvider` | Private IOReport energy/temp channels | **Stubbed / gated** (`isEnabled=false`) | Off by default; enable in Settings → Metrics |
| CPU power W | `IOReportTelemetryProvider` | Private IOReport Energy Model | **Stubbed / gated** | Off by default |
| GPU temperature °C | `IOReportTelemetryProvider` | Private IOReport GPU Stats | **Stubbed / gated** | Off by default (hidden when unavailable) |
| GPU power W | `IOReportTelemetryProvider` | Private IOReport Energy Model | **Stubbed / gated** | Off by default |
| GPU utilization % | `IOReportTelemetryProvider` | Private IOReport | **Stubbed / gated** | Off by default |
| Package power W | `IOReportTelemetryProvider` | Private IOReport | **Stubbed / gated** | Returns `nil` → `--` |
| FPS (HUD) | `DisplayLinkFPSProvider` | Public `CVDisplayLink` | **Implemented** as *local display-link cadence* | **Not** other-apps' game FPS |
| Display Hz | `DisplayLinkFPSProvider` | `CVDisplayLinkGetNominalOutputVideoRefreshPeriod` | **Implemented** | Separate from game FPS |
| System-wide game FPS | `ScreenCaptureFPSProvider` | Public ScreenCaptureKit + Screen Recording TCC | **Stubbed** | Always `nil` until implemented |

## Private Apple Silicon interfaces (`IOReportTelemetryProvider`)

| Field | Value |
|---|---|
| API | Undocumented IOReport channel APIs commonly referenced as `IOReportCopyChannelsInGroup`, `IOReportCreateSubscription`, `IOReportCreateSamples`, etc. |
| Linkage | Not linked against a public SDK module; production enablement should use `dlsym` / weak import |
| macOS versions | Channel names observed to drift across macOS 12–15; re-validate per OS |
| Chips | Intended for Apple Silicon M1–M4; M5 untested. Intel uses different SMC paths |
| Permissions | Typically incompatible with App Sandbox / Mac App Store without special tooling entitlements |
| Unavailable behavior | `sample()` returns a snapshot with all private fields `nil`; UI shows `--` |
| App Store | Private API usage risks rejection — keep gated behind `isEnabled` |

### Enabling (developers only)

1. Validate channel maps on a physical Apple Silicon Mac for your macOS build.
2. Implement `samplePrivateChannels()` with real parses only.
3. Construct `IOReportTelemetryProvider(isEnabled: true)` from `TelemetryBootstrap` after verification.
4. Flip availability from `.requiresPrivateAPI` to `.available` only for channels that return real data.

## FPS reality check

The reference HUD shows an **FPS** value. Public macOS APIs do not expose another process's rendered frame rate. This project therefore:

1. Ships `DisplayLinkFPSProvider` (this app's display-link callback rate / refresh).
2. Stubs `ScreenCaptureFPSProvider` for a future Screen Recording–permission path that estimates FPS from captured frame timestamps.
3. Refuses to invent an FPS number when neither provider can measure.

## Production wiring

`TelemetryBootstrap.makeComposite(enablePrivateIOReport: false)` is what `SiliconStatsApp` uses. No mock telemetry is connected in the app target.

## Default HUD (schema v2)

The overlay shows **CPU % · MEM · FPS** by default (public Mach + DisplayLink). CPU/GPU °C and W stay off until private IOReport sampling is validated, so the pill no longer fills with `--` for metrics we cannot read yet.

## Default HUD (schema v2)

The pill shows **CPU % · MEM · FPS** by default — metrics available from public Mach / DisplayLink APIs. GPU °C/W and CPU °C/W remain available in Settings but stay off until private IOReport sampling is validated, so the overlay no longer fills with `--`.

