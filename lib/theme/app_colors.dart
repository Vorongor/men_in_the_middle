import 'package:flutter/material.dart';

/// Classic Terminal palette — Variant 1 from color_map.md.
///
/// Migration cheatsheet (old → new):
///   Colors.black / Color(0xFF0A0A0A) / Color(0xFF0D0D0D)  → AppColors.bg
///   Color(0xFF111111) / Color(0xFF121417)                  → AppColors.surface
///   Color(0xFF0C160C) / Color(0xFF1A1A0D)                  → AppColors.surfaceSuccess
///   Color(0xFF240C0C)                                      → AppColors.surfaceError
///   Colors.greenAccent / Color(0xFF39D353) / Color(0xFF00FF41) → AppColors.primary
///   Color(0xFF008F11) / Color(0xFF1E351E) / Color(0xFF2E2E2E)  → AppColors.secondary
///   Colors.white / Colors.white70 / Colors.white54         → AppColors.text
///   Colors.white38 / Colors.white24                        → AppColors.textMuted
///   Colors.redAccent / Color(0xFFFF003C)                   → AppColors.alert
///   Colors.orangeAccent / Colors.amberAccent               → AppColors.warning
abstract final class AppColors {
  // ── Core Palette ─────────────────────────────────────────────────────────
  /// Very deep almost-black with cold tint — primary background.
  static const Color bg = Color(0xFF0A0A0C);

  /// Slightly lighter black — cards, dialogs, AppBar.
  static const Color surface = Color(0xFF121417);

  /// Success-tinted surface — snackbar success bg, positive badges.
  static const Color surfaceSuccess = Color(0xFF0C160C);

  /// Error-tinted surface — snackbar error bg, danger badges.
  static const Color surfaceError = Color(0xFF240C0C);

  /// Classic hacker green — CTA buttons, active accents, highlights.
  static const Color primary = Color(0xFF00FF41);

  /// Muted green — inactive elements, borders, grid lines.
  static const Color secondary = Color(0xFF008F11);

  /// Main readable text — light grey (not pure white, reduces eye strain).
  static const Color text = Color(0xFFE0E0E0);

  /// Muted text — subtitles, captions, secondary labels.
  /// Contrast ≥ 4.5:1 on [bg] verified.
  static const Color textMuted = Color(0xFF8A9099);

  /// Danger / Wanted — aggressive red for failures and alerts.
  static const Color alert = Color(0xFFFF003C);

  /// Warning — amber/orange for underpowered attacks and cautionary labels.
  static const Color warning = Color(0xFFFFB800);

  // ── Border & Divider helpers ──────────────────────────────────────────────
  /// Subtle divider line between surface elements.
  static const Color divider = Color(0xFF1A1A1A);

  /// Slightly more visible border for cards and containers.
  static const Color border = Color(0xFF2E2E2E);

  /// Success-tinted border used alongside [surfaceSuccess].
  static const Color borderSuccess = Color(0xFF1E351E);

  // ── Scrims (overlays above video/image backgrounds) ───────────────────────
  /// Standard darkening veil over a background video/image so text stays
  /// readable. Replaces the inline `Color(0x88000000)` overlays.
  static const Color scrim = Color(0x88000000);

  /// Heavier veil for screens with dense foreground content (auth forms).
  /// Replaces the inline `Color(0xAA000000)` overlay.
  static const Color scrimStrong = Color(0xAA000000);

  // ── Text opacity helpers (semantic aliases) ───────────────────────────────
  /// White at 70% — used for AppBar foreground, moderate emphasis text.
  static const Color textHigh = Color(0xFFB3B3B3); // ≈ white70 on black

  /// Translucent icon tint for low-emphasis chevrons and icons.
  static Color get iconLow => text.withValues(alpha: 0.24);
}
