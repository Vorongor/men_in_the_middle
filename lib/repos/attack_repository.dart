import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../game/resolution/attack_models.dart';
import '../services/level_service.dart';

/// What happened when an [AttackResolution] was persisted, including
/// whether it pushed the player across a level threshold.
class AttackApplyResult {
  final AttackResolution resolution;
  final bool leveledUp;
  final int? newLevelId;
  final String? newLevelName;

  const AttackApplyResult({
    required this.resolution,
    this.leveledUp = false,
    this.newLevelId,
    this.newLevelName,
  });
}

/// One row of a player's attack history, joined with readable target/mission
/// names — backs the Profile screen's "Recent Operations" section.
class AttackHistoryEntry {
  final String targetName;
  final String missionName;
  final String result;
  final int eptsDelta;
  final int wantedDelta;
  final int trustDelta;
  final String createdAt;

  const AttackHistoryEntry({
    required this.targetName,
    required this.missionName,
    required this.result,
    required this.eptsDelta,
    required this.wantedDelta,
    required this.trustDelta,
    required this.createdAt,
  });
}

/// Persists the consequences of a resolved attack: profile deltas (clamped
/// to their DB CHECK bounds), the contract completion flag, the attack_log
/// entry, and a minimal level-up check — all in a single transaction.
class AttackRepository {
  final DatabaseHelper _db;
  const AttackRepository(this._db);

  Future<AttackApplyResult> applyResolution({
    required int profileId,
    required int contractId,
    required int targetTemplateId,
    required int missionTypeId,
    required AttackResolution resolution,
  }) async {
    final d = await _db.db;

    return d.transaction((txn) async {
      final profileMaps =
          await txn.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      if (profileMaps.isEmpty) throw Exception('Profile not found');
      final p = profileMaps.first;

      final newEpts = (p['epts_balance'] as int) + resolution.eptsDelta;
      final newExp = (p['experience'] as int) + resolution.expDelta;
      final newWanted =
          ((p['wanted'] as int) + resolution.wantedDelta).clamp(0, 100);
      final newTrust =
          ((p['black_trust'] as int) + resolution.trustDelta).clamp(0, 100);
      final currentLevelId = p['level_id'] as int;

      await txn.update(
        'profiles',
        {
          'epts_balance': newEpts,
          'experience': newExp,
          'wanted': newWanted,
          'black_trust': newTrust,
        },
        where: 'id = ?',
        whereArgs: [profileId],
      );

      await txn.update(
        'active_contracts',
        {'is_completed': 1},
        where: 'id = ?',
        whereArgs: [contractId],
      );

      await txn.insert('attack_log', {
        'profile_id': profileId,
        'target_template_id': targetTemplateId,
        'mission_type_id': missionTypeId,
        'result': resolution.result.dbValue,
        'epts_delta': resolution.eptsDelta,
        'wanted_delta': resolution.wantedDelta,
        'trust_delta': resolution.trustDelta,
      });

      final newLevelId = await LevelService.resolveLevel(currentLevelId, newExp);
      var leveledUp = false;
      String? newLevelName;
      if (newLevelId != currentLevelId) {
        leveledUp = true;
        await txn.update(
          'profiles',
          {'level_id': newLevelId},
          where: 'id = ?',
          whereArgs: [profileId],
        );
        final levelRows =
            await txn.query('levels', where: 'id = ?', whereArgs: [newLevelId]);
        if (levelRows.isNotEmpty) {
          newLevelName = levelRows.first['name'] as String;
        }
      }

      return AttackApplyResult(
        resolution: resolution,
        leveledUp: leveledUp,
        newLevelId: leveledUp ? newLevelId : null,
        newLevelName: newLevelName,
      );
    });
  }

  /// The player's most recent attacks, newest first — for the Profile
  /// screen's "Recent Operations" section.
  Future<List<AttackHistoryEntry>> recentAttacks(int profileId, {int limit = 5}) async {
    final d = await _db.db;
    final rows = await d.rawQuery('''
      SELECT al.result, al.epts_delta, al.wanted_delta, al.trust_delta, al.created_at,
             tt.name AS target_name, mt.name AS mission_name
      FROM attack_log al
      JOIN target_templates tt ON al.target_template_id = tt.id
      JOIN mission_types mt ON al.mission_type_id = mt.id
      WHERE al.profile_id = ?
      ORDER BY al.id DESC
      LIMIT ?
    ''', [profileId, limit]);

    return rows
        .map((r) => AttackHistoryEntry(
              targetName: r['target_name'] as String,
              missionName: r['mission_name'] as String,
              result: r['result'] as String,
              eptsDelta: r['epts_delta'] as int,
              wantedDelta: r['wanted_delta'] as int,
              trustDelta: r['trust_delta'] as int,
              createdAt: r['created_at'] as String,
            ))
        .toList();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final attackRepositoryProvider = Provider<AttackRepository>(
  (ref) => AttackRepository(DatabaseHelper.instance),
);
