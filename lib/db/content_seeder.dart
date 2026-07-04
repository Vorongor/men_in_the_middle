import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/content_validator.dart';

/// Seeds the catalog tables in SQLite database from JSON asset files
/// when a new database is created or when the content version increases.
class ContentSeeder {
  static const currentContentVersion = 1;

  static Future<void> seed(Database db) async {
    // 1. Create meta table if not exists (insurance)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 2. Check current version
    final maps = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: ['content_version'],
    );
    int versionInDb = 0;
    if (maps.isNotEmpty) {
      versionInDb = int.tryParse(maps.first['value'] as String) ?? 0;
    }

    if (versionInDb >= currentContentVersion) {
      // Already seeded up to date
      return;
    }

    // 3. Load asset files
    final targetTypesJson =
        await rootBundle.loadString('assets/data/catalog/target_types.json');
    final missionTypesJson =
        await rootBundle.loadString('assets/data/catalog/mission_types.json');
    final softwareItemsJson =
        await rootBundle.loadString('assets/data/catalog/software_items.json');
    final hardwareItemsJson =
        await rootBundle.loadString('assets/data/catalog/hardware_items.json');
    final targetTemplatesJson = await rootBundle
        .loadString('assets/data/catalog/target_templates.json');
    final effectivenessJson =
        await rootBundle.loadString('assets/data/catalog/effectiveness.json');
    final levelCurveJson =
        await rootBundle.loadString('assets/data/catalog/level_curve.json');

    // 4. Validate content before inserting
    ContentValidator.validate(
      softwareItemsJson: softwareItemsJson,
      hardwareItemsJson: hardwareItemsJson,
      targetTypesJson: targetTypesJson,
      targetTemplatesJson: targetTemplatesJson,
      missionTypesJson: missionTypesJson,
      effectivenessJson: effectivenessJson,
      levelCurveJson: levelCurveJson,
    );

    // 5. Seed inside a transaction to ensure atomicity
    await db.transaction((txn) async {
      // Clear existing catalogs
      await txn.delete('effectiveness_matrix');
      await txn.delete('target_templates');
      await txn.delete('hardware_items');
      await txn.delete('software_items');
      await txn.delete('target_types');
      await txn.delete('mission_types');

      // Insert target_types
      final targetTypes = (jsonDecode(targetTypesJson) as List<dynamic>).cast<Map<String, dynamic>>();
      for (final raw in targetTypes) {
        await txn.insert('target_types', {
          'id': raw['id'] as int,
          'name': raw['name'] as String,
          'base_trace_speed': raw['base_trace_speed'] as int,
          'risk_multiplier': (raw['risk_multiplier'] as num).toDouble(),
        });
      }

      // Insert mission_types
      final missionTypes = (jsonDecode(missionTypesJson) as List<dynamic>).cast<Map<String, dynamic>>();
      for (final raw in missionTypes) {
        await txn.insert('mission_types', {
          'id': raw['id'] as int,
          'name': raw['name'] as String,
          'description': raw['description'] as String,
          'primary_soft_type_id': raw['primary_soft_type_id'] as int,
          'base_reward_mult': (raw['base_reward_mult'] as num).toDouble(),
        });
      }

      // Insert software_items
      final softwareItems = (jsonDecode(softwareItemsJson) as List<dynamic>).cast<Map<String, dynamic>>();
      for (final raw in softwareItems) {
        await txn.insert('software_items', {
          'id': raw['id'] as int,
          'name': raw['name'] as String,
          'soft_type_id': raw['soft_type_id'] as int,
          'description': raw['description'] as String,
          'base_price': raw['base_price'] as int,
          'currency_type': raw['currency_type'] as String? ?? 'EPTS',
          'req_level': raw['req_level'] as int? ?? 1,
          'req_black_trust': raw['req_black_trust'] as int? ?? 0,
          'init_max_level': raw['init_max_level'] as int? ?? 5,
          'base_attack': raw['base_attack'] as int,
          'base_penetration': raw['base_penetration'] as int,
          'base_trace': raw['base_trace'] as int,
          'sockets': raw['sockets'] as int? ?? 1,
          'level_up_strategy': jsonEncode(raw['level_up_strategy']),
        });
      }

      // Insert hardware_items
      final hardwareItems = (jsonDecode(hardwareItemsJson) as List<dynamic>).cast<Map<String, dynamic>>();
      for (final raw in hardwareItems) {
        await txn.insert('hardware_items', {
          'id': raw['id'] as int,
          'name': raw['name'] as String,
          'hw_type': raw['hw_type'] as String,
          'description': raw['description'] as String,
          'base_price': raw['base_price'] as int,
          'currency_type': raw['currency_type'] as String? ?? 'EPTS',
          'req_level': raw['req_level'] as int? ?? 1,
          'req_black_trust': raw['req_black_trust'] as int? ?? 0,
          'init_compute_power': raw['init_compute_power'] as int,
          'init_power_draw': raw['init_power_draw'] as int,
          'sockets': raw['sockets'] as int? ?? 1,
        });
      }

      // Insert target_templates
      final targetTemplates = (jsonDecode(targetTemplatesJson) as List<dynamic>).cast<Map<String, dynamic>>();
      for (final raw in targetTemplates) {
        await txn.insert('target_templates', {
          'id': raw['id'] as int,
          'type_id': raw['type_id'] as int,
          'name': raw['name'] as String,
          'required_level': raw['required_level'] as int? ?? 1,
          'base_defense': raw['base_defense'] as int,
          'epts_reward': raw['epts_reward'] as int,
          'trust_reward': raw['trust_reward'] as int,
          'custom_mechanics': jsonEncode(raw['custom_mechanics']),
        });
      }

      // Insert effectiveness_matrix
      final effectiveness = (jsonDecode(effectivenessJson) as List<dynamic>).cast<Map<String, dynamic>>();
      for (final raw in effectiveness) {
        await txn.insert('effectiveness_matrix', {
          'soft_type_id': raw['soft_type_id'] as int,
          'target_type_id': raw['target_type_id'] as int,
          'damage_mult': (raw['damage_mult'] as num).toDouble(),
          'trace_mult': (raw['trace_mult'] as num).toDouble(),
        });
      }

      // 6. Write version key
      await txn.insert(
        'meta',
        {'key': 'content_version', 'value': currentContentVersion.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
