import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography presets for The MiddleMen.
///
/// Font roles:
///   **GeistPixel** — headings, section labels, CTA buttons, stat values.
///                    Minimum size: 14px (below this pixel font becomes unreadable).
///   **Share Tech Mono** (via google_fonts) — body text, data readouts, captions.
///                    Minimum size: body ≥ 13px, caption ≥ 11px.
///
/// Rule: never use any font directly in screens — always use these presets.
abstract final class AppTextStyles {
  // ── GeistPixel presets ───────────────────────────────────────────────────

  /// Large display heading — screen titles, splash text. GeistPixel 20+.
  static TextStyle displayTitle({Color? color}) => TextStyle(
        fontFamily: 'GeistPixel',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.5,
        color: color ?? AppColors.text,
      );

  /// AppBar / section heading — moderate weight, spaced caps. GeistPixel 14.
  static TextStyle sectionLabel({Color? color}) => TextStyle(
        fontFamily: 'GeistPixel',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
        color: color ?? AppColors.text,
      );

  /// Button label — prominent, letter-spaced. GeistPixel 14.
  static TextStyle button({Color? color}) => TextStyle(
        fontFamily: 'GeistPixel',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: color ?? AppColors.primary,
      );

  /// Numeric stat value displayed in heads-up panels. GeistPixel 16.
  static TextStyle statValue({Color? color}) => TextStyle(
        fontFamily: 'GeistPixel',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color ?? AppColors.primary,
      );

  // ── Share Tech Mono presets ──────────────────────────────────────────────

  /// Standard body text — item names, descriptions. STM 13px.
  static TextStyle body({Color? color}) => GoogleFonts.shareTechMono(
        fontSize: 13,
        color: color ?? AppColors.text,
      );

  /// Data readout — numbers, codes, log entries. STM 13px bold.
  static TextStyle dataMono({Color? color}) => GoogleFonts.shareTechMono(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: color ?? AppColors.text,
      );

  /// Small caption / metadata — time stamps, categories, secondary labels.
  /// Minimum 11px as per design spec.
  static TextStyle caption({Color? color}) => GoogleFonts.shareTechMono(
        fontSize: 11,
        color: color ?? AppColors.textMuted,
      );

  /// Snackbar message text. STM 12px bold, letter-spaced.
  static TextStyle snackMessage({Color? color}) => GoogleFonts.shareTechMono(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: color ?? AppColors.text,
      );
}
