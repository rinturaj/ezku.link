---
name: ezku.link
description: Ultra-fast macOS screen mirroring and 4K Smart TV casting utility
colors:
  primary: "#F59E0B"
  primary-hover: "#D97706"
  neutral-bg: "#FAF8F5"
  neutral-bg-subtle: "#F3EFE6"
  neutral-card: "#FFFFFF"
  neutral-card-alt: "#F8F6F0"
  neutral-ink: "#16140E"
  neutral-ink-muted: "#706C62"
  neutral-ink-subtle: "#A8A49A"
  live-green: "#10B981"
  field-note: "#FFE894"
  dark-bg: "#090A0F"
  dark-card: "#141722"
  dark-ink: "#F3F0E6"
typography:
  display:
    fontFamily: '"General Sans", "Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    fontSize: "clamp(46px, 6vw, 84px)"
    fontWeight: 600
    lineHeight: 0.96
    letterSpacing: "-0.04em"
  headline:
    fontFamily: '"General Sans", "Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    fontSize: "clamp(32px, 3.8vw, 48px)"
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: "-0.03em"
  title:
    fontFamily: '"General Sans", "Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    fontSize: "clamp(26px, 2.8vw, 36px)"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.025em"
  body:
    fontFamily: '"General Sans", "Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.65
    letterSpacing: "normal"
  label:
    fontFamily: '"IBM Plex Mono", ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace'
    fontSize: "11px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.08em"
rounded:
  xs: "4px"
  sm: "6px"
  md: "10px"
  lg: "16px"
  xl: "24px"
  pill: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "48px"
  section: "clamp(64px, 10vw, 120px)"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#000000"
    rounded: "{rounded.pill}"
    padding: "12px 24px"
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
  button-secondary:
    backgroundColor: "{colors.neutral-card}"
    textColor: "{colors.neutral-ink}"
    rounded: "{rounded.pill}"
    padding: "12px 24px"
  card-default:
    backgroundColor: "{colors.neutral-card}"
    rounded: "{rounded.lg}"
    padding: "32px"
  badge-accent:
    backgroundColor: "{colors.primary}"
    textColor: "#000000"
    rounded: "{rounded.sm}"
    padding: "5px 12px"
---

# Design System: ezku.link

## Overview

**Creative North Star: "The Technical Manuscript"**

ezku.link embodies the tactile discipline of an engineering notebook crossed with mid-century Swiss editorial layout and Apple hardware utility. Every surface feels grounded on physical warm parchment rather than synthetic sterile white, anchored by fine ruled notebook grid lines and crisp hairline framing. The interface communicates high-bandwidth technical reality—zero latency, hardware decode protocols, zero-copy GPU buffers—with warmth, precision, and confidence.

The design firmly rejects standard modern AI SaaS tropes: no pastel purple gradients, no fuzzy drop-shadowed blob cards, no corporate 3D clay figures, and no neon glow overkill. Interactive elements feel like precision instruments: crisp pill buttons with tactile spring physics, monospace telemetry meters with pulsating radar status dots, and tactile corner brackets that expand dynamically when an element gains focus.

**Key Characteristics:**
- Warm parchment background with subtle 28px ruled horizontal guide lines and 120px vertical grid lines.
- High-contrast carbon ink typography paired with precise monospace instrumentation and metadata tags.
- Tactile framing: 1px hairline borders complemented by interactive Signal Amber corner brackets on focus/hover.
- Focused color restraint: Signal Amber reserved exclusively for active states and high-priority conversion triggers.

## Colors

The palette balances warm organic paper tones with precise carbon ink, illuminated by high-visibility Signal Amber and active Radar Green telemetry accents.

### Primary
- **Signal Amber** (`#F59E0B`): The solitary active accent color. Used for primary CTA buttons, featured badge indicators, and interactive corner bracket highlights. Darkens to `#D97706` on hover; deepens to rich amber tints for glow states.

### Neutral
- **Warm Parchment** (`#FAF8F5`): Default page canvas. Evokes high-grade book paper, providing warmth and reducing visual fatigue. Shifts to deep obsidian (`#090A0F`) in dark mode.
- **Subtle Parchment Tint** (`#F3EFE6`): Background for tertiary containers, alternating rows, and section transitions (`#12141D` in dark mode).
- **Pure Paper Card** (`#FFFFFF`): Elevated card and container background (`#141722` in dark mode).
- **Deep Carbon Ink** (`#16140E`): Primary headline and body typography, offering deep contrast without harsh pure black (`#F3F0E6` in dark mode).
- **Secondary Ink** (`#3E3B33`): Sub-headlines, lead paragraph copy, and emphasized labels (`#B3B0A4` in dark mode).
- **Muted Ink** (`#706C62`): Secondary copy, captions, and inactive tab labels (`#75746C` in dark mode).
- **Hairline Border** (`rgba(22, 20, 14, 0.11)`): Structural 1px division and card outline (`rgba(255, 255, 255, 0.10)` in dark mode).

### Accent & Telemetry
- **Radar Green** (`#10B981`): Dedicated telemetry indicator representing real-time system status, live stream connections, and sub-30ms performance verification.
- **Field Note Ochre** (`#FFE894`): Tactile callout container evoking a physical paper sticky note for crucial architectural takeaways (`#D99B26` in dark mode).

### Named Rules
**The One Signal Rule.** Signal Amber is strictly restricted to ≤10% of any viewport. Its purpose is to guide user decisions, command downloads, and highlight active connections. It must never be used for general decorative backgrounds or low-priority body copy.

**The Ruled Ground Rule.** Canvas surfaces rest on the subtle 28px ruled notebook line pattern (`var(--ruled-line)`). Content lives within structured spatial lines rather than floating untethered on empty white.

## Typography

**Display Font:** "General Sans", "Plus Jakarta Sans", -apple-system, sans-serif
**Body Font:** "General Sans", "Plus Jakarta Sans", -apple-system, sans-serif
**Label/Mono Font:** "IBM Plex Mono", ui-monospace, SFMono-Regular, monospace

**Character:** The pairing of General Sans and IBM Plex Mono creates an intellectual, utilitarian harmony—editorial clarity in editorial headlines coupled with the uncompromising mechanical precision of a terminal or hardware spec sheet.

### Hierarchy
- **Display** (weight 600, `clamp(46px, 6vw, 84px)`, line-height 0.96, tracking -0.04em): Hero main statement; dramatic scale with tight negative tracking.
- **Headline** (weight 600, `clamp(32px, 3.8vw, 48px)`, line-height 1.1, tracking -0.03em): Major section headers ("How It Works", "Smart TV Compatibility").
- **Title** (weight 600, `clamp(26px, 2.8vw, 36px)`, line-height 1.2, tracking -0.025em): Card titles, step headings, and modal titles.
- **Lead Body** (weight 400, `clamp(17px, 1.4vw, 20px)`, line-height 1.55): Section introductory blurbs; maximum measure 65–70ch.
- **Body** (weight 400, 16px, line-height 1.65): Explanatory copy, feature descriptions, and FAQ answers.
- **Label / Mono** (weight 600, 11px to 12.5px, line-height 1.2, tracking 0.08em, uppercase): Telemetry readouts, version tags, step counters (`STEP 01`), and pill badges.

### Named Rules
**The Monospace Telemetry Rule.** All technical metrics, version strings, protocol identifiers (DLNA, CastV2, Rec.709), and system specifications must be rendered in `IBM Plex Mono` with uppercase tracking.

## Layout

The spatial model relies on a centered master container with a generous 1240px boundary, framed by responsive horizontal margins (`clamp(20px, 4vw, 48px)`).

- **Master Container:** `.page-container` max-width 1240px, centered with automatic margins.
- **Vertical Rhythm:** Major sections use generous breathing room (`clamp(64px, 10vw, 120px)`), with compact sub-sections spaced at `clamp(40px, 6vw, 72px)`.
- **Card Grids:** Repeatable 3-column and 4-column responsive auto-fit grids (`grid-template-columns: repeat(auto-fit, minmax(280px, 1fr))`) with 20px to 24px gutters.
- **Section Headers:** Structured row pairing a left-aligned badge cluster with a right-aligned decorative corner mark (`⌟`), establishing a clear technical baseline.

## Elevation & Depth

The system is flat and grounded by default. Depth is conveyed primarily through tonal layering (warm parchment background transitioning into pure white card surfaces and 1px hairline strokes) rather than blurry drop shadows.

### Shadow Vocabulary
- **Ambient Subtle** (`box-shadow: 0 1px 3px rgba(22, 20, 14, 0.04)`): Rest state for cards and primary buttons; prevents harsh edge clipping.
- **Card Hover Elevation** (`box-shadow: 0 8px 24px -6px rgba(22, 20, 14, 0.07)`): Triggered on container hover, accompanied by a -2px vertical translation.
- **Signal Ambient Glow** (`box-shadow: 0 12px 32px -8px rgba(245, 158, 11, 0.35)`): Reserved for hover states on primary Signal Amber CTA buttons.
- **Sticky Note Tactile** (`box-shadow: 0 8px 20px -4px rgba(26, 18, 2, 0.15)`): Applied specifically to Field Note callout blocks.

### Named Rules
**The Flat-At-Rest Rule.** All cards and containers remain completely flat at rest, distinguished solely by 1px hairline borders (`var(--line)`) and subtle surface contrast. Shadows activate strictly as a response to user hover, focus, or elevation state.

## Shapes

The form language combines organic pill curves for interactive gestures with sharp, disciplined geometry for informational cards and technical metadata tags.

- **Interactive Pills (`border-radius: 9999px`):** Primary and secondary buttons, interactive filter pills, and navigation capsules.
- **Content Cards (`border-radius: 16px`):** Feature blocks, step cards, and matrix grids.
- **Technical Badges (`border-radius: 6px`):** Status indicators, version chips, and step labels.
- **Corner Brackets (`.corner-bracket`):** Distinctive 8px x 8px 2px-thick L-shaped brackets pinned to opposite diagonal corners of cards (top-right and bottom-left). On card hover, they dynamically expand to 14px x 14px in Signal Amber.

## Components

### Buttons
- **Shape:** Pill radius (9999px) with 12px 24px internal padding.
- **Primary:** Background in Signal Amber (`#F59E0B`), text in pure black (`#000000`), subtle diagonal attention sheen animation (`btn-shimmer`). On hover: lifts -2px, scales to 1.02, shifts to `#D97706`, and projects amber glow. On active press: tactile scale down to 0.96.
- **Secondary:** Background in pure card paper (`#FFFFFF`), text in Carbon Ink (`#16140E`), bordered with 1px hairline (`var(--line)`). On hover: lifts -2px with subtle card background shift.

### Badges & Status Chips
- **Shape:** Compact 6px radius, padding 5px 12px, set in uppercase IBM Plex Mono (11px, 0.08em tracking).
- **Default Badge:** Background in Subtle Parchment (`#F8F6F0`), 1px hairline border, Carbon Ink text.
- **Accent Badge:** Background in Signal Amber (`#F59E0B`), pure black text, bold weight.
- **Live Telemetry Badge:** Background in transparent emerald tint (`rgba(16, 185, 129, 0.12)`), text in Radar Green (`#10B981`), housing a 6px pulsating circular radar dot (`.live-dot`).

### Cards & Containers
- **Shape:** 16px radius, bordered with 1px hairline (`rgba(22, 20, 14, 0.11)`), internal padding `clamp(24px, 3vw, 36px)`.
- **States:** Flat at rest; on hover lifts -2px with `--shadow-md` and expands opposite corner brackets from 8px to 14px.

### Field Note Callout (Sticky Note)
- **Shape:** 10px radius, background in Field Note Ochre (`#FFE894`), dark text (`#1A1202`), tactile drop shadow.
- **Typography:** Features uppercase monospace category tag over bold 19px condensed headline and italic subtext.

### Header & Navigation
- **Style:** Sticky fixed bar with backdrop blur (`backdrop-filter: blur(12px)`), hairline bottom border, brand icon with live status dot, centered anchor navigation, and Pleurat-style circular half-moon theme toggle button.

## Do's and Don'ts

### Do:
- **Do** anchor viewports with the subtle 28px ruled horizontal guide line background (`var(--ruled-line)`).
- **Do** format technical specs, bitrates, latency numbers, and version numbers in uppercase `IBM Plex Mono`.
- **Do** preserve the tactile diagonal corner brackets (`.corner-bracket`) on elevated content cards.
- **Do** use pill curves (`border-radius: 9999px`) for all actionable button triggers.
- **Do** use Radar Green with pulsating radar dots strictly for real-time live connection indicators.

### Don't:
- **Don't** use generic multi-color AI SaaS neon mesh gradients or purple-blue blur blobs.
- **Don't** flood screens with Signal Amber; maintain the ≤10% surface budget so action points stay potent.
- **Don't** place cards on unbordered white backgrounds without either hairline borders or ruled grid structure.
- **Don't** invent artificial 3D clay illustrations, stock vector avatars, or placeholder customer logos.
- **Don't** introduce heavy dark drop shadows at rest; keep elevation flat until user interaction triggers state change.
