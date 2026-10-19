# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users
- Primary: Mac users (macOS 14+ Sonoma & Sequoia, Apple Silicon M1-M4) who want effortless, instant screen mirroring and local 4K video streaming to Smart TVs and second screens.
- Context & Situation: Working from home, relaxing on the couch, presenting in conference rooms or classrooms, or sharing content without cables, dongles, or setting up complex media server software.
- Core Job: Stream displays, specific windows, or local media files to a Smart TV or nearby browser in one click from the macOS menu bar, without installing any app on the TV or running third-party players like VLC or Airflow.

## Product Purpose
- Purpose: Provide a high-converting, crystal-clear, and aesthetically refined web landing and distribution surface for ezku.link.
- Success: Clear product comprehension in seconds, immediate answers to TV compatibility questions (zero TV apps or third-party players needed), trust in 100% local privacy, and smooth direct download of the macOS DMG installer.

## Positioning
- Zero TV app requirement: Connects directly via native Google Cast V2 and DLNA / UPnP protocols built into Samsung Tizen, LG webOS, Sony Bravia, Roku, and Chromecast TVs.
- Sub-30ms ultra-low latency powered by Apple ScreenCaptureKit zero-copy capture and Metal GPU hardware acceleration on Apple Silicon.
- Integrated zero-client web receiver (HTML5 Canvas + Web Audio API) with instant QR code scanning for viewing in any local browser.
- Direct 4K video casting via HTTP 206 byte-range streaming with TV hardware decoding and physical TV remote control playback.
- 100% local Wi-Fi, zero accounts, zero cloud servers, zero telemetry tracking.

## Operating Context
- Surface: Web landing and product distribution site built with SvelteKit 2, Svelte 5 (runes), TypeScript, and Vite.
- Distribution: Direct download DMG distribution (`/downloads/ezku.link.dmg`) and open-source Swift codebase on GitHub (`rinturajc/ezkuCasting`).
- Environment: Responsive web application optimized for modern desktop and mobile browsers, supporting both light and dark themes with editorial warm paper aesthetics.
- Machine discovery: `static/llms.txt` and `static/llms-full.txt` providing structured LLM documentation.

## Capabilities and Constraints
- Capabilities:
  - Technical product presentation: Hero with direct DMG download, How to Use workflow guide, interactive demo video showcase, Smart TV compatibility matrix (Samsung, LG, Sony, Roku, Chromecast), technical FAQ with Schema.org JSON-LD, and persistent menu bar popover preview.
  - Theme switching: Warm paper editorial light mode (`--bg: #FAF8F5`) and dark mode (`--bg: #090A0F`).
  - Structured data: Complete Schema.org `SoftwareApplication`, `FAQPage`, and `WebSite` JSON-LD markup.
- Constraints:
  - Target platform for this repository is strictly `web`.
  - Must accurately describe macOS 14.0+ (Apple Silicon) system requirements and local network prerequisites without misleading claims.
  - Zero fabricated testimonials, non-existent features, or false benchmarks.

## Brand Commitments
- Name: ezku.link (alternate: ezkuCasting).
- Tone & Voice: Technical clarity, confident craftsmanship, minimalist modern editorial, respectful and direct. No marketing fluff or hype.
- Key Visual Identity: Editorial typography ("General Sans", "IBM Plex Mono"), warm paper and ink palette with vibrant amber accent (`#F59E0B`), live telemetry indicators (`#10B981`), and authentic macOS menu bar iconography (`/MenuBarIcon@2x.png`).

## Evidence on Hand
- App icon and graphics: `static/MenuBarIcon@2x.png`, `static/dmg_background.png`, `static/favicon.png`.
- Demo assets: `src/lib/components/DemoVideo.svelte` interactive mock preview.
- Technical documentation: `static/llms.txt`, `static/llms-full.txt`.
- GitHub repository reference: `https://github.com/rinturajc/ezkuCasting`.
- Installer endpoint: `https://ezku.link/downloads/ezku.link.dmg`.

## Product Principles
1. Immediate Truth Over Hype: Clearly explain how it works mechanically (native TV protocols, Apple ScreenCaptureKit, zero TV apps required) rather than using vague buzzwords.
2. Respect Local Privacy: Prominently emphasize that streaming is 100% local over home Wi-Fi with no accounts, cloud servers, or data collection.
3. Speed and Craft: The web interface should reflect the performance and precision of the native utility—fast loading, responsive, and thoughtfully typeset.
4. Frictionless Onboarding: Prioritize 1-click download and immediately answer the primary buyer question: "Does this work with my TV without an app?"
