# Silicon Stats

Native macOS menu-bar HUD for Apple Silicon performance monitoring — floating black pill overlay for CPU, GPU, and FPS.

Visual target: horizontal capsule with **CPU** (blue) · **GPU** (cyan-gray) · **FPS** (mint), white values, ~85–90% opaque black pill.

> **Note:** This repository was authored in a Linux cloud environment. Open and build on an Apple Silicon Mac with Xcode 15+. Metrics that depend on macOS/hardware are documented in [`Docs/TELEMETRY.md`](Docs/TELEMETRY.md) — unavailable values show as `--`, never fabricated.

## Requirements

- macOS 13.0+
- Apple Silicon Mac recommended (M1–M5)
- Xcode 15 or newer

## Open / build / run

```bash
open SiliconStats.xcodeproj
```

In Xcode:

1. Select the **Silicon Stats** scheme and **My Mac** (Apple Silicon).
2. **Product → Build** (`⌘B`), then **Run** (`⌘R`).
3. Grant any prompted permissions later if you enable ScreenCapture-based FPS.

CLI:

```bash
xcodebuild -scheme "Silicon Stats" -destination 'platform=macOS' build
xcodebuild -scheme "Silicon Stats" -destination 'platform=macOS' test
```

The app is a menu-bar utility (`LSUIElement`): look for the chip icon in the status bar. Use **Toggle Overlay** / **Settings…**.

## Project layout

```
SiliconStats.xcodeproj/     Xcode project + shared scheme
SiliconStats/
  App/                      NSApplication entry, menu bar, telemetry monitor
  Overlay/                  NSPanel controller + SwiftUI pill HUD
  Telemetry/                TelemetryProvider + Mach / IOReport providers
  FPS/                      FPSProvider + DisplayLink / ScreenCapture stubs
  Settings/                 SwiftUI settings + UserDefaults store
  Models/                   PerformanceSnapshot, AppSettings, availability
  Utilities/                Formatting, unit conversion, FPS math
  Resources/                Info.plist, Assets
SiliconStatsTests/          Unit tests (formatter, snapshot, FPS, settings, units)
Docs/TELEMETRY.md           Real vs stubbed metrics + private API notes
```

## Metrics honesty

| Shown on pill | Source in this build |
|---|---|
| CPU °C / W | Private IOReport path **gated off** → `--` until validated |
| GPU °C / W | Same → `--` |
| FPS | `CVDisplayLink` local cadence when running on macOS; not other-apps' game FPS |
| CPU % / memory | Implemented via public Mach APIs (optional in Metrics settings) |

Details: [`Docs/TELEMETRY.md`](Docs/TELEMETRY.md).

## Architecture

- `TelemetryProvider` / `FPSProvider` protocols
- `PerformanceSnapshot` with optional fields only
- AppKit `NSPanel` overlay (borderless, transparent, always-on-top, optional click-through)
- SwiftUI settings (General / Metrics / Appearance)
- Telemetry polling separated from UI observation

## License

MIT — see [LICENSE](LICENSE).
