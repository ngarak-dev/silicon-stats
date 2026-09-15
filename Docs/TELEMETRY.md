# Telemetry & FPS sources

Silicon Stats never fabricates sensor or FPS values. Missing data renders as `--` (or the metric group is hidden when configured).

This cloud/Linux environment cannot compile or validate macOS binaries. Treat hardware-dependent rows as **unverified** until exercised on Apple Silicon.

## Metric matrix

| Metric | Provider | API surface | Status in this build | Notes |
|---|---|---|---|---|
| CPU utilization % (aggregate) | `CPULoadTelemetryProvider` | Public Mach `host_processor_info` / `PROCESSOR_CPU_LOAD_INFO` | **Implemented** (unverified on device in CI) | Idle/busy tick deltas across logical cores |
| Per-core CPU % | `CPULoadTelemetryProvider` | Same as above | **Implemented** — HUD mini-bars when enabled | One bar per logical core |
| Memory used / cached / free | `MemoryTelemetryProvider` | Public Mach `host_statistics64` / `HOST_VM_INFO64` | **Implemented** | Used = active+wired+compressed; Cached = inactive+speculative; Free = free pages |
| Memory wired / compressed | `MemoryTelemetryProvider` | Same | **In snapshot** (optional HUD) | Available on `PerformanceSnapshot` for future UI |
| Thermal state | `ThermalStateTelemetryProvider` | Public `ProcessInfo.thermalState` | **Implemented** — qualitative only | Does **not** map to °C |
| CPU temperature °C | `IOReportTelemetryProvider` | Private IOReport via `dlsym` | **Best-effort** when Settings → Enable IOReport | Returns `nil` if framework/channels fail |
| CPU power W | `IOReportTelemetryProvider` | Private IOReport Energy Model deltas | **Best-effort** when enabled | ∆energy / ∆t; unit heuristics |
| GPU temperature °C | `IOReportTelemetryProvider` | Private IOReport temp-like groups | **Best-effort** when enabled | Channel names drift across OS |
| GPU power W | `IOReportTelemetryProvider` | Private IOReport Energy Model | **Best-effort** when enabled | |
| GPU utilization % | `IOReportTelemetryProvider` | Private IOReport | **Not parsed yet** | Stays `nil` → `--` / hidden |
| Package power W | `IOReportTelemetryProvider` | Private IOReport Energy Model | **Best-effort** when enabled | Sum of matched energy channels |
| FPS (HUD) | `DisplayLinkFPSProvider` | Public `CVDisplayLink` | **Implemented** as *local display-link cadence* | **Not** other-apps' game FPS |
| Display Hz | `DisplayLinkFPSProvider` | `CVDisplayLinkGetNominalOutputVideoRefreshPeriod` | **Implemented** | Separate from game FPS |
| System-wide game FPS | `ScreenCaptureFPSProvider` | Public ScreenCaptureKit + Screen Recording TCC | **Stubbed** | Always `nil` until implemented |

## Memory semantics

Aligned with Activity Monitor–style Mach VM accounting (not `vm_stat` labels alone):

| HUD label | Meaning |
|---|---|
| **U** | Used — active + wired + compressor pages |
| **C** | Cached — inactive + speculative (reclaimable under pressure) |
| **F** | Free — free pages |

Wired and compressed remain on the snapshot for diagnostics; the default pill shows U / C / F.

## Private Apple Silicon interfaces (`IOReportTelemetryProvider`)

| Field | Value |
|---|---|
| API | Undocumented IOReport: `IOReportCopyChannelsInGroup`, `IOReportCreateSubscription`, `IOReportCreateSamples`, `IOReportIterate`, `IOReportSimpleGetIntegerValue`, … |
| Linkage | `dlopen` / `dlsym` on `IOReport.framework` — not linked as a public SDK module |
| Groups probed | `Energy Model`, `CPU Stats`, `GPU Stats`, `CLPC Stats`, `PMP` |
| macOS versions | Channel names drift across macOS 12–15; re-validate per OS |
| Chips | Intended for Apple Silicon M1–M4; M5 untested. Intel uses different SMC paths |
| Permissions | Often incompatible with App Sandbox / Mac App Store without tooling entitlements |
| Unavailable behavior | `sample()` returns `nil` private fields; UI shows `--` or hides |
| App Store | Private API usage risks rejection — keep behind **Enable IOReport °C / W** |

### Enabling

1. Settings → Metrics → **Enable IOReport °C / W**.
2. Optionally turn on CPU/GPU Temperature and Power visibility.
3. On a real Mac, confirm values look sane under load; if not, leave disabled (HUD keeps Mach CPU/MEM + FPS).

Developers validating channel maps should adjust name matchers in `IOReportTelemetryProvider` after on-device captures — never invent fallback numbers.

## FPS reality check

The reference HUD shows an **FPS** value. Public macOS APIs do not expose another process's rendered frame rate. This project therefore:

1. Ships `DisplayLinkFPSProvider` (this app's display-link callback rate / refresh).
2. Stubs `ScreenCaptureFPSProvider` for a future Screen Recording–permission path that estimates FPS from captured frame timestamps.
3. Refuses to invent an FPS number when neither provider can measure.

## Production wiring

`TelemetryBootstrap.makeBundle(enablePrivateIOReport:)` builds Mach + thermal + IOReport + DisplayLink providers. `TelemetryMonitor` mirrors Settings `enablePrivateSensors` onto `IOReportTelemetryProvider.isEnabled` at runtime. No mock telemetry is connected in the app target.

## Default HUD (schema v3)

The pill shows **CPU % + per-core bars · MEM U/C/F · FPS** by default (public Mach + DisplayLink). CPU/GPU °C and W stay off until the user enables private IOReport **and** turns those metric toggles on.
