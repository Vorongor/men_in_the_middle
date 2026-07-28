import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/economy_tuning.dart';
import '../models/hardware_item.dart';
import '../models/profile.dart';
import '../models/software_item.dart';
import '../models/target_template.dart';

/// Handles software / hardware catalog and targeting queries.
class CatalogRepository {
  final DatabaseHelper _db;
  const CatalogRepository(this._db);

  /// Fetches available software items in the store for the given player profile,
  /// filtered by level and black market trust requirements.
  Future<List<SoftwareItem>> storeItems(Profile profile) async {
    final d = await _db.db;
    final maps = await d.query(
      'software_items',
      where: 'req_level <= ? AND req_black_trust <= ?',
      whereArgs: [profile.levelId, profile.blackTrust],
    );
    return maps.map(SoftwareItem.fromMap).toList();
  }

  /// Fetches all software items in the catalog.
  Future<List<SoftwareItem>> allSoftwareItems() async {
    final d = await _db.db;
    final maps = await d.query('software_items');
    return maps.map(SoftwareItem.fromMap).toList();
  }

  /// Fetches available hardware items on the market for the given player profile,
  /// filtered by level and black market trust requirements.
  Future<List<HardwareItem>> marketItems(Profile profile) async {
    final d = await _db.db;
    final maps = await d.query(
      'hardware_items',
      where: 'req_level <= ? AND req_black_trust <= ?',
      whereArgs: [profile.levelId, profile.blackTrust],
    );
    return maps.map(HardwareItem.fromMap).toList();
  }

  /// Fetches all hardware items in the catalog.
  Future<List<HardwareItem>> allHardwareItems() async {
    final d = await _db.db;
    final maps = await d.query('hardware_items');
    return maps.map(HardwareItem.fromMap).toList();
  }

  /// Fetches target templates available for the given player level.
  Future<List<TargetTemplate>> targetTemplatesFor(int level) async {
    final d = await _db.db;
    final maps = await d.query(
      'target_templates',
      where: 'required_level <= ?',
      whereArgs: [level],
    );
    return maps.map(TargetTemplate.fromMap).toList();
  }

  /// Fetches damage and trace multipliers from the effectiveness matrix.
  /// Returns a tuple `(damageMult, traceMult)`. Fallbacks to `(1.0, 1.0)`.
  Future<(double, double)> effectiveness(int softTypeId, int targetTypeId) async {
    final d = await _db.db;
    final maps = await d.query(
      'effectiveness_matrix',
      where: 'soft_type_id = ? AND target_type_id = ?',
      whereArgs: [softTypeId, targetTypeId],
    );
    if (maps.isEmpty) return (1.0, 1.0);
    final row = maps.first;
    return (
      (row['damage_mult'] as num).toDouble(),
      (row['trace_mult'] as num).toDouble(),
    );
  }

  /// Fetches the whole effectiveness matrix as a single lookup, keyed by
  /// `(softTypeId, targetTypeId)`. Used by Attack Prep so switching the
  /// selected software doesn't need a DB round-trip per tap.
  Future<Map<(int, int), (double, double)>> effectivenessMatrix() async {
    final d = await _db.db;
    final maps = await d.query('effectiveness_matrix');
    return {
      for (final row in maps)
        (row['soft_type_id'] as int, row['target_type_id'] as int): (
          (row['damage_mult'] as num).toDouble(),
          (row['trace_mult'] as num).toDouble(),
        ),
    };
  }

  /// Fetches the economy tuning configuration from meta.
  Future<EconomyTuning> fetchEconomyTuning() async =>
      EconomyTuning.load(await _db.db);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(DatabaseHelper.instance),
);

final economyTuningProvider = FutureProvider<EconomyTuning>((ref) async {
  return ref.watch(catalogRepositoryProvider).fetchEconomyTuning();
});
