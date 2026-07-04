import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/account_with_profile.dart';

/// Reads and updates player profile data.
class ProfileRepository {
  const ProfileRepository(this._db);
  final DatabaseHelper _db;

  /// Fetches the full AccountWithProfile by account id.
  Future<AccountWithProfile?> fetchAccountWithProfile(int accountId) async {
    final d = await _db.db;
    final rows = await d.rawQuery(
      '${DatabaseHelper.joinedSelect} WHERE a.id = ?',
      [accountId],
    );
    if (rows.isEmpty) return null;
    return DatabaseHelper.rowToAccountWithProfile(rows.first);
  }

  /// Applies numeric deltas to a profile row.
  ///
  /// Example: `applyDeltas(profileId, {'experience': 100, 'wanted': 5})`
  /// All values are clamped by DB CHECK constraints automatically.
  Future<void> applyDeltas(int profileId, Map<String, int> deltas) async {
    if (deltas.isEmpty) return;
    final setClauses = deltas.keys.map((k) => '$k = $k + ?').join(', ');
    final values = [...deltas.values, profileId];
    final d = await _db.db;
    await d.rawUpdate(
      'UPDATE profiles SET $setClauses WHERE id = ?',
      values,
    );
  }

  /// Sets profile fields to exact values (used for direct assignments).
  Future<void> setFields(int profileId, Map<String, Object> fields) async {
    if (fields.isEmpty) return;
    final setClauses = fields.keys.map((k) => '$k = ?').join(', ');
    final values = [...fields.values, profileId];
    final d = await _db.db;
    await d.rawUpdate(
      'UPDATE profiles SET $setClauses WHERE id = ?',
      values,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(DatabaseHelper.instance),
);
