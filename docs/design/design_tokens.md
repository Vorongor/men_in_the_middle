# Design Tokens — The MiddleMen

This document outlines the core visual system, color palette, typography presets, spacing, and guidelines.

## Color System

The color system is based on **Variant 1 "Classic Terminal"** from `color_map.md`. It uses high-contrast, cybersecurity-themed primary colors on top of cold, dark backgrounds to create an immersive hacker aesthetic.

### Palette

| Token | HEX | Sample/Preview | Usage Description |
|---|---|---|---|
| `bg` | `#0A0A0C` | ⬛ | Primary background of all screens, very dark blue-black. |
| `surface` | `#121417` | ⬛ | Lighter grey-black for container cards, navigation bars, and dialogue backgrounds. |
| `surfaceSuccess` | `#0C160C` | ⬛ | Success green background tint for positive badges and transaction statuses. |
| `surfaceError` | `#240C0C` | ⬛ | Red background tint for dismissed items, failed transactions, and error statuses. |
| `primary` | `#00FF41` | 🟩 | Classic hacker green. Active call-to-actions, successful labels, active indicators. |
| `secondary` | `#008F11` | 🟩 | Muted matrix green. Borders, gridlines, inactive tab states. |
| `text` | `#E0E0E0` | ⬜ | Primary body text color. Off-white to minimize eye strain. |
| `textMuted` | `#8A9099` | ⬜ | Muted grey-blue. Metadata, subtext, descriptors, and secondary info. |
| `alert` | `#FF003C` | 🟥 | Aggressive cyber red. Danger states, warnings, active tracing, failures. |
| `warning` | `#FFB800` | 🟨 | Amber/Orange. Warning labels, risky forecasts, tax/charge notices. |
| `divider` | `#1A1A1A` | ⬛ | Border lines and list dividers. |
| `border` | `#2E2E2E` | ⬛ | Standard outline borders for cards and inactive items. |

---

## Typography

The typography system uses two distinct fonts:
1.  **Geist Pixel** — A pixel-based typeface used exclusively for headers, titles, primary CTA labels, and main numerical status displays.
2.  **Share Tech Mono** — A clean monospace typeface used for tabular datasets, readability lists, secondary labels, and dense text descriptions.

> [!IMPORTANT]
> To prevent pixel fonts from rendering incorrectly or breaking on low-to-medium DPI screens, **never use Geist Pixel with a font size smaller than 14px**.

### Typography Scale

| Style Token | Font Family | Size | Weight | Details | Usage |
|---|---|---|---|---|---|
| `displayTitle` | Geist Pixel | 20px | Bold | Letter spacing: 2.5 | Screen titles, Main menus |
| `sectionLabel` | Geist Pixel | 14px | w600 | Letter spacing: 2.0 | Section headers, AppBars |
| `button` | Geist Pixel | 14px | Bold | Letter spacing: 1.5 | Primary CTA button labels |
| `statValue` | Geist Pixel | 16px | Bold | | Balance stats, prominent numbers |
| `body` | Share Tech Mono | 13px | Normal | | Description paragraphs, dialogs |
| `dataMono` | Share Tech Mono | 13px | Bold | | Key-value records, parameters |
| `caption` | Share Tech Mono | 11px | Normal | | Timestamps, muted labels, footers |

---

## Spacing and Radius

All margins, paddings, and container shapes adhere to a 4px grid.

### Spacing Scale

*   `xs`: `4.0` (Minimal separators, tight badges)
*   `sm`: `8.0` (Row items spacing, internal chip padding)
*   `md`: `12.0` (Standard grid gaps, button internal vertical padding)
*   `lg`: `16.0` (Section padding, standard margins)
*   `xl`: `20.0` (Hub page card padding, screen headers margins)
*   `xxl`: `24.0` (Scaffold content edge margins)

### Border Radius

*   `radiusSm`: `2.0` (Status tags, compact labels)
*   `radiusMd`: `4.0` (Primary action buttons, standard lists, chips)
*   `radiusLg`: `8.0` (Dialogues, overlay cards, floating panels)

---

## Code Example: UI Migration Reference

### Before (Inline style overrides)
```dart
Text(
  'UPGRADE SOFTWARE',
  style: GoogleFonts.shareTechMono(
    color: Colors.greenAccent,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  ),
);
```

### After (Design System Token integration)
```dart
Text(
  'UPGRADE SOFTWARE',
  style: AppTextStyles.button(color: AppColors.primary).copyWith(fontSize: 12),
);
```
