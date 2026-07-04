import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

/// Tracks which one-time onboarding tips the player has already dismissed,
/// backed by the `meta` key/value table (the same table ContentSeeder uses
/// for `content_version`). A tip is local to this install, not per-profile —
/// there's only one player per device in this alpha, so that's an acceptable
/// simplification.
class OnboardingRepository {
  final DatabaseHelper _db;
  const OnboardingRepository(this._db);

  static String _key(String tipKey) => 'tutorial_$tipKey';

  Future<bool> hasSeen(String tipKey) async {
    final d = await _db.db;
    final rows = await d.query('meta', where: 'key = ?', whereArgs: [_key(tipKey)]);
    return rows.isNotEmpty;
  }

  Future<void> markSeen(String tipKey) async {
    final d = await _db.db;
    await d.insert(
      'meta',
      {'key': _key(tipKey), 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(DatabaseHelper.instance),
);
