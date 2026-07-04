import 'dart:convert';

import 'package:flutter/services.dart';

class LevelCurveEntry {
  final int level;
  final int reqExp;
  const LevelCurveEntry(this.level, this.reqExp);
}

/// Loads and caches `assets/data/catalog/level_curve.json`.
///
/// The full progression system (unlock notifications, req_level gating
/// everywhere) belongs to Step 09; this loader only backs the minimal
/// "did the player cross a threshold" check attack resolution needs to show
/// a rank-up banner.
class LevelCurve {
  const LevelCurve._();

  static List<LevelCurveEntry>? _cache;

  static Future<List<LevelCurveEntry>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw =
        await rootBundle.loadString('assets/data/catalog/level_curve.json');
    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    final entries = list
        .map((m) => LevelCurveEntry(m['level'] as int, m['req_exp'] as int))
        .toList()
      ..sort((a, b) => a.level.compareTo(b.level));

    _cache = entries;
    return entries;
  }

  /// Highest level whose `req_exp` is met by [experience], never lower than
  /// [currentLevel] (levels never regress).
  static int resolveLevel(List<LevelCurveEntry> curve, int currentLevel, int experience) {
    var resolved = currentLevel;
    for (final entry in curve) {
      if (entry.level > resolved && experience >= entry.reqExp) {
        resolved = entry.level;
      }
    }
    return resolved;
  }

  static LevelCurveEntry? _find(List<LevelCurveEntry> curve, int level) {
    for (final entry in curve) {
      if (entry.level == level) return entry;
    }
    return null;
  }

  /// Fraction (0..1) of the way from [currentLevel]'s threshold to the next
  /// seeded level's threshold, for a Profile screen XP bar. Returns 1.0 once
  /// there's no higher level in the curve (max rank reached).
  static double progressFraction(
    List<LevelCurveEntry> curve,
    int currentLevel,
    int experience,
  ) {
    final currentReq = _find(curve, currentLevel)?.reqExp ?? 0;
    final nextReq = _find(curve, currentLevel + 1)?.reqExp;
    if (nextReq == null || nextReq <= currentReq) return 1.0;
    return ((experience - currentReq) / (nextReq - currentReq)).clamp(0.0, 1.0);
  }
}
