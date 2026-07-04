import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../game/resolution/resolution_engine.dart';
import '../models/active_contract.dart';
import '../models/profile.dart';
import '../models/target_template.dart';
import '../utils/wanted_effects.dart';
import 'inventory_repository.dart';

/// Handles dynamic contract generation and target board retrieval queries.
class TargetRepository {
  final DatabaseHelper _db;
  const TargetRepository(this._db);

  /// Fetches all active (uncompleted) contracts for the given player profile.
  Future<List<ContractDetails>> fetchActiveContracts(int profileId) async {
    final d = await _db.db;
    final List<Map<String, dynamic>> maps = await d.rawQuery('''
      SELECT
        ac.id, ac.profile_id, ac.target_template_id, ac.mission_type_id, ac.defense, ac.epts_reward, ac.trust_reward, ac.expires_at, ac.is_completed, ac.is_honeypot,
        tt.name AS target_name, tt.required_level AS target_required_level, tt.custom_mechanics AS target_custom_mechanics,
        tty.id AS target_type_id, tty.name AS target_type_name, tty.base_trace_speed AS target_base_trace_speed, tty.risk_multiplier AS target_risk_multiplier,
        mt.name AS mission_name, mt.description AS mission_description, mt.primary_soft_type_id AS mission_primary_soft_type_id
      FROM active_contracts ac
      JOIN target_templates tt ON ac.target_template_id = tt.id
      JOIN target_types tty ON tt.type_id = tty.id
      JOIN mission_types mt ON ac.mission_type_id = mt.id
      WHERE ac.profile_id = ? AND ac.is_completed = 0
    ''', [profileId]);
    return maps.map(ContractDetails.fromMap).toList();
  }

  /// Fetches a single contract details by ID.
  Future<ContractDetails?> fetchContractDetails(int contractId) async {
    final d = await _db.db;
    final List<Map<String, dynamic>> maps = await d.rawQuery('''
      SELECT
        ac.id, ac.profile_id, ac.target_template_id, ac.mission_type_id, ac.defense, ac.epts_reward, ac.trust_reward, ac.expires_at, ac.is_completed, ac.is_honeypot,
        tt.name AS target_name, tt.required_level AS target_required_level, tt.custom_mechanics AS target_custom_mechanics,
        tty.id AS target_type_id, tty.name AS target_type_name, tty.base_trace_speed AS target_base_trace_speed, tty.risk_multiplier AS target_risk_multiplier,
        mt.name AS mission_name, mt.description AS mission_description, mt.primary_soft_type_id AS mission_primary_soft_type_id
      FROM active_contracts ac
      JOIN target_templates tt ON ac.target_template_id = tt.id
      JOIN target_types tty ON tt.type_id = tty.id
      JOIN mission_types mt ON ac.mission_type_id = mt.id
      WHERE ac.id = ?
    ''', [contractId]);
    if (maps.isEmpty) return null;
    return ContractDetails.fromMap(maps.first);
  }

  /// Refreshes (regenerates) 5 to 7 contracts for the given player.
  /// If [payFee] is true, deducts 10 EPTS from their balance (throws InsufficientFundsException if not enough).
  /// Generates a randomized list that guarantees at least 1 "easy" contract and 1 "hard" contract.
  Future<void> refreshContracts(Profile profile, {bool payFee = false, int? customSeed}) async {
    final d = await _db.db;
    final rand = customSeed != null ? Random(customSeed) : Random();

    await d.transaction((txn) async {
      final profileId = profile.id!;

      // 1. Pay fee if requested
      if (payFee) {
        final profileMaps = await txn.query('profiles', where: 'id = ?', whereArgs: [profileId]);
        if (profileMaps.isEmpty) throw Exception('Profile not found');
        final currentEpts = profileMaps.first['epts_balance'] as int;

        const fee = 10;
        if (currentEpts < fee) {
          throw const InsufficientFundsException();
        }

        await txn.update(
          'profiles',
          {'epts_balance': currentEpts - fee},
          where: 'id = ?',
          whereArgs: [profileId],
        );
      }

      // 2. Delete current uncompleted contracts
      await txn.delete(
        'active_contracts',
        where: 'profile_id = ? AND is_completed = 0',
        whereArgs: [profileId],
      );

      // 3. Fetch templates and mission multipliers. The Clean Up Traces
      // template is excluded here — it never appears as a random bounty, it
      // is only ever offered via ensureCleanUpContract().
      final templateMaps = await txn.query(
        'target_templates',
        where: 'required_level <= ? AND name != ?',
        whereArgs: [profile.levelId + 1, _cleanUpTemplateName],
      );
      final templates = templateMaps.map(TargetTemplate.fromMap).toList();

      final missionMaps = await txn.query('mission_types');
      final missionMults = {
        for (var m in missionMaps) m['id'] as int: (m['base_reward_mult'] as num).toDouble()
      };

      if (templates.isEmpty) return;

      // 4. Categorize templates
      final easy = templates.where((t) => profile.levelId > 1 ? t.requiredLevel < profile.levelId : t.requiredLevel == 1).toList();
      final hard = templates.where((t) => t.requiredLevel == profile.levelId + 1).toList();
      final mid = templates.where((t) => t.requiredLevel == profile.levelId).toList();

      // 5. Select templates to generate (count: 5-7)
      final count = 5 + rand.nextInt(3);
      final selectedTemplates = <TargetTemplate>[];

      // Guarantee at least 1 easy template
      if (easy.isNotEmpty) {
        selectedTemplates.add(easy[rand.nextInt(easy.length)]);
      } else if (mid.isNotEmpty) {
        selectedTemplates.add(mid[rand.nextInt(mid.length)]);
      }

      // Guarantee at least 1 hard template
      if (hard.isNotEmpty) {
        selectedTemplates.add(hard[rand.nextInt(hard.length)]);
      } else if (mid.isNotEmpty) {
        selectedTemplates.add(mid[rand.nextInt(mid.length)]);
      }

      // Fill remainder randomly
      while (selectedTemplates.length < count) {
        selectedTemplates.add(templates[rand.nextInt(templates.length)]);
      }

      // 6. At elevated wanted, one slot on the board is a silent trap —
      // never labeled in the UI, it just always fails on attack (see
      // ResolutionEngine.resolve). Picked once per refresh, independent of
      // which template ends up there.
      final honeypotIndex = WantedEffects.honeypotActive(profile.wanted) && selectedTemplates.isNotEmpty
          ? rand.nextInt(selectedTemplates.length)
          : -1;

      // 7. Generate and insert contracts
      for (var i = 0; i < selectedTemplates.length; i++) {
        final template = selectedTemplates[i];
        final variation = 0.85 + rand.nextDouble() * 0.30; // ±15% variation
        final missionTypeId = _getMissionTypeIdForTargetType(template.typeId);
        final rewardMult = missionMults[missionTypeId] ?? 1.0;

        final defense = (template.baseDefense * variation).round().clamp(1, 999999);
        final epts = (template.eptsReward * rewardMult * variation).round();
        final trust = (template.trustReward * rewardMult * variation).round();

        await txn.insert('active_contracts', {
          'profile_id': profileId,
          'target_template_id': template.id,
          'mission_type_id': missionTypeId,
          'defense': defense,
          'epts_reward': epts,
          'trust_reward': trust,
          'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'is_completed': 0,
          'is_honeypot': i == honeypotIndex ? 1 : 0,
        });
      }
    });
  }

  int _getMissionTypeIdForTargetType(int targetTypeId) {
    if (targetTypeId == 1 || targetTypeId == 2 || targetTypeId == 3) return 1; // Data Theft
    if (targetTypeId == 4) return 2; // Password Cracking
    if (targetTypeId == 5 || targetTypeId == 6) return 4; // Code Injection
    if (targetTypeId == 7) return 3; // System Sabotage
    return 1;
  }

  /// Name of the single seeded target_template backing every Clean Up Traces
  /// contract (assets/data/catalog/target_templates.json). Looked up by name
  /// rather than a hardcoded id since content ids can shift as the catalog
  /// grows; the mission_type id is still hardcoded (see
  /// [ResolutionEngine.cleanUpMissionTypeId]) to match this codebase's
  /// existing convention for the four original mission types.
  static const _cleanUpTemplateName = 'Digital Footprint Cleanup';

  /// Ensures the player has exactly one open Clean Up Traces contract,
  /// creating it if needed, and returns its id. Used to force a way out once
  /// wanted hits the raid threshold (see [WantedEffects.raidThreshold]).
  Future<int> ensureCleanUpContract(int profileId) async {
    final d = await _db.db;
    return d.transaction((txn) async {
      final existing = await txn.rawQuery('''
        SELECT ac.id FROM active_contracts ac
        WHERE ac.profile_id = ? AND ac.is_completed = 0
          AND ac.mission_type_id = ?
        LIMIT 1
      ''', [profileId, ResolutionEngine.cleanUpMissionTypeId]);
      if (existing.isNotEmpty) {
        return existing.first['id'] as int;
      }

      final templateRows = await txn.query(
        'target_templates',
        where: 'name = ?',
        whereArgs: [_cleanUpTemplateName],
        limit: 1,
      );
      if (templateRows.isEmpty) {
        throw StateError('Clean Up Traces target template is not seeded');
      }
      final template = TargetTemplate.fromMap(templateRows.first);

      return txn.insert('active_contracts', {
        'profile_id': profileId,
        'target_template_id': template.id,
        'mission_type_id': ResolutionEngine.cleanUpMissionTypeId,
        'defense': template.baseDefense,
        'epts_reward': 0,
        'trust_reward': 0,
        'expires_at': null,
        'is_completed': 0,
        'is_honeypot': 0,
      });
    });
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final targetRepositoryProvider = Provider<TargetRepository>(
  (ref) => TargetRepository(DatabaseHelper.instance),
);
