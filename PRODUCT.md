# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

Mac power users, developers, presenters, and multitaskers who need instant wireless secondary monitors and ultra-low-latency screen mirroring to Smart TVs and web displays.

## Product Purpose

Transform any Smart TV (Chromecast, DLNA/UPnP, Samsung Tizen, LG webOS, Sony Bravia, Roku) or web browser into a wireless second display or mirrored screen directly from the macOS menu bar in 1 click with sub-30ms latency. Success means seamless zero-driver virtual display operation, instant device discovery on local Wi-Fi, and rock-solid broadcast stability without requiring third-party TV apps or hardware dongles.

## Positioning

Hardware-accelerated macOS streaming utility built natively for Apple Silicon (Metal GPU pipeline + ScreenCaptureKit zero-copy capture) coupled with a user-space virtual display engine and universal direct-to-TV streaming protocols (Google Cast V2 and DLNA AVTransport). Unlike cloud-tethered or driver-heavy alternatives, ezku.link operates entirely locally in user space with zero kernel extensions, zero TV-side app installs, and zero latency penalties.

## Operating Context

- macOS 14.0+ (Sonoma, Sequoia) on Apple Silicon (M1, M2, M3, M4).
- Headless / dockless menu bar status item (`NSStatusItem`, `LSUIElement`) living in the top macOS menu bar.
- Tight integration with macOS WindowServer, Mission Control, Spaces, and Display Arrangement settings.
- Local Wi-Fi network environment connecting Mac to smart TVs and companion devices.
- Live telemetry HUD monitoring frame rate (FPS), bitrate, encode latency, and connected client sessions.

## Capabilities and Constraints

- **Capabilities**:
  - Direct Smart TV streaming via Google Cast (Chromecast) and DLNA / UPnP AVTransport protocols.
  - Virtual Extended Screen (1080p, 1440p, 4K at 60 FPS) turning any TV or browser into a functional second monitor.
  - Zero-client web streaming with local HTTP/WebSocket streaming server and QR code pairing.
  - Direct 4K video casting via HTTP byte-range streaming for local video files.
  - Metal GPU compression pipeline (`CIContext` on Metal) with sub-3ms encode latency.
  - Menu bar popover with real-time telemetry, display mode toggles, and quality presets (Ultra 60 FPS, Retina Native, Battery Saver).
- **Constraints**:
  - Requires macOS 14.0+ and Apple Silicon hardware.
  - Requires macOS Screen & System Audio Recording permissions.
  - Dependent on local Wi-Fi network connectivity and multicast/mDNS/SSDP discovery.

## Brand Commitments

- **Name**: `ezku.link` (binary `EzkuLink`, bundle identifier `link.ezku.mac`).
- **Design Philosophy**: Apple Human Interface Guidelines and Apple Design principles (`.agents/skills/apple-design`), engineered to feel like native Apple system software.
- **Brand Palette**: Modern Anthropic brand palette integrated in [AppTheme.swift](file:///Users/rinturajc/FrontEnd/ezkuCasting/Sources/EzkuLink/UI/AppTheme.swift) (Dark `#141413`, Warm Accent Orange `#d97757`, Slate Blue `#6a9bcc`, Sage Green `#788c5d`, Off-White `#faf9f5`).

## Evidence on Hand

- Native Swift 6 code repository: [Package.swift](file:///Users/rinturajc/FrontEnd/ezkuCasting/Package.swift), [Sources/EzkuLink/](file:///Users/rinturajc/FrontEnd/ezkuCasting/Sources/EzkuLink).
- Packaging & build pipeline: [Scripts/build_app.sh](file:///Users/rinturajc/FrontEnd/ezkuCasting/Scripts/build_app.sh), [Scripts/build_dmg.sh](file:///Users/rinturajc/FrontEnd/ezkuCasting/Scripts/build_dmg.sh).
- App metadata and icons: [Resources/AppIcon.icns](file:///Users/rinturajc/FrontEnd/ezkuCasting/Resources/AppIcon.icns), [Resources/Info.plist](file:///Users/rinturajc/FrontEnd/ezkuCasting/Resources/Info.plist).
- Comprehensive documentation: [README.md](file:///Users/rinturajc/FrontEnd/ezkuCasting/README.md).

## Product Principles

1. **Frictionless Presence**: Live silently in the menu bar; connect in a single click with zero software installation on the receiving TV or device.
2. **Native Apple Precision**: Adhere strictly to Apple HIG, system materials, smooth spring animations, and SF Symbols so the utility feels like an integral part of macOS.
3. **Uncompromising Latency & Fidelity**: Exploit Apple Silicon GPU pipelines and Metal encoding for sub-30ms responsiveness and crisp text legibility.
4. **Transparent Telemetry**: Surface critical operational feedback (FPS, bitrate, encode latency) concisely without cluttering the user interface.

## Accessibility & Inclusion

- Full VoiceOver support for all menu bar popover buttons, sliders, and picker elements with explicit accessibility labels and hints.
- Dynamic adaptation to macOS Dark Mode and system contrast preferences.
- Respect system Reduce Motion preferences by substituting gentle opacity crossfades for dynamic spring translations.
