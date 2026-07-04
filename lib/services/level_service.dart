import '../utils/level_curve.dart';

/// Thin seam over [LevelCurve] so both the attack-resolution pipeline and
/// the Profile screen's XP bar share one source of truth for "what level is
/// this experience worth" instead of loading/parsing the curve separately.
class LevelService {
  const LevelService._();

  /// Resolves the level for [experience], never regressing below
  /// [currentLevel]. Callers persist the result themselves.
  static Future<int> resolveLevel(int currentLevel, int experience) async {
    final curve = await LevelCurve.load();
    return LevelCurve.resolveLevel(curve, currentLevel, experience);
  }

  /// Progress (0..1) from [currentLevel]'s threshold to the next one, for a
  /// Profile screen XP bar. 1.0 once there's no higher seeded level.
  static Future<double> progressToNextLevel(int currentLevel, int experience) async {
    final curve = await LevelCurve.load();
    return LevelCurve.progressFraction(curve, currentLevel, experience);
  }
}
