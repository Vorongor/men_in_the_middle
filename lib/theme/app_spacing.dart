/// Spacing scale and border-radius tokens for The MiddleMen.
///
/// Use these instead of raw numeric literals to keep layouts consistent.
abstract final class AppSpacing {
  // ── Spacing scale (multiples of 4) ───────────────────────────────────────
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;

  // ── Standard padding presets ─────────────────────────────────────────────
  /// Horizontal padding used in list tiles and screen content.
  static const double screenH = xl;

  /// Vertical padding for list-tile content.
  static const double tileV = md;

  // ── Border radius ─────────────────────────────────────────────────────────
  /// Tight — icon containers, small badges.
  static const double radiusSm = 2.0;

  /// Standard — cards, buttons, containers.
  static const double radiusMd = 4.0;

  /// Large — dialogs, bottom sheets.
  static const double radiusLg = 8.0;
}
