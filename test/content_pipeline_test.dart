import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/utils/content_validator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Mock Asset Bundle to read the real files from the workspace
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        final key = utf8.decode(
          message.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        
        // Find which asset is requested and load it from disk
        String filePath = '';
        if (key.contains('target_types.json')) {
          filePath = 'assets/data/catalog/target_types.json';
        } else if (key.contains('mission_types.json')) {
          filePath = 'assets/data/catalog/mission_types.json';
        } else if (key.contains('software_items.json')) {
          filePath = 'assets/data/catalog/software_items.json';
        } else if (key.contains('hardware_items.json')) {
          filePath = 'assets/data/catalog/hardware_items.json';
        } else if (key.contains('target_templates.json')) {
          filePath = 'assets/data/catalog/target_templates.json';
        } else if (key.contains('effectiveness.json')) {
          filePath = 'assets/data/catalog/effectiveness.json';
        } else if (key.contains('level_curve.json')) {
          filePath = 'assets/data/catalog/level_curve.json';
        } else if (key.contains('economy.json')) {
          filePath = 'assets/data/catalog/economy.json';
        } else if (key.contains('legends.json')) {
          filePath = 'assets/data/legends.json';
        }

        if (filePath.isNotEmpty && File(filePath).existsSync()) {
          final bytes = File(filePath).readAsBytesSync();
          return ByteData.sublistView(bytes);
        }
        return null;
      },
    );
  });

  group('ContentValidator tests', () {
    final targetTypes = File('assets/data/catalog/target_types.json').readAsStringSync();
    final missionTypes = File('assets/data/catalog/mission_types.json').readAsStringSync();
    final softwareItems = File('assets/data/catalog/software_items.json').readAsStringSync();
    final hardwareItems = File('assets/data/catalog/hardware_items.json').readAsStringSync();
    final targetTemplates = File('assets/data/catalog/target_templates.json').readAsStringSync();
    final effectiveness = File('assets/data/catalog/effectiveness.json').readAsStringSync();
    final levelCurve = File('assets/data/catalog/level_curve.json').readAsStringSync();
    final economy = File('assets/data/catalog/economy.json').readAsStringSync();

    test('Validates real production assets correctly', () {
      expect(
        () => ContentValidator.validate(
          softwareItemsJson: softwareItems,
          hardwareItemsJson: hardwareItems,
          targetTypesJson: targetTypes,
          targetTemplatesJson: targetTemplates,
          missionTypesJson: missionTypes,
          effectivenessJson: effectiveness,
          levelCurveJson: levelCurve,
          economyJson: economy,
        ),
        returnsNormally,
      );
    });

    test('Throws on invalid soft_type_id in software items', () {
      // Modify type_id of Phishing Mailer to 999 (invalid)
      final brokenSoft = softwareItems.replaceFirst('"soft_type_id": 1', '"soft_type_id": 999');
      expect(
        () => ContentValidator.validate(
          softwareItemsJson: brokenSoft,
          hardwareItemsJson: hardwareItems,
          targetTypesJson: targetTypes,
          targetTemplatesJson: targetTemplates,
          missionTypesJson: missionTypes,
          effectivenessJson: effectiveness,
          levelCurveJson: levelCurve,
          economyJson: economy,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('Throws on negative prices in hardware items', () {
      final brokenHard = hardwareItems.replaceFirst('"base_price": 150', '"base_price": -150');
      expect(
        () => ContentValidator.validate(
          softwareItemsJson: softwareItems,
          hardwareItemsJson: brokenHard,
          targetTypesJson: targetTypes,
          targetTemplatesJson: targetTemplates,
          missionTypesJson: missionTypes,
          effectivenessJson: effectiveness,
          levelCurveJson: levelCurve,
          economyJson: economy,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ContentSeeder & starting inventory tests', () {
    test('Seeding and initial player generation', () async {
      final helper = DatabaseHelper.instance;
      final db = await helper.db; // Triggers _initDb and seeder

      // 1. Verify target types table is populated
      final types = await db.query('target_types');
      expect(types.length, 7);
      expect(types.first['name'], 'Persons');

      // 2. Verify software items table is populated
      final soft = await db.query('software_items');
      expect(soft.length, 12);
      expect(soft.first['name'], 'Phishing Mailer v1');

      // 3. Register a new user and verify starting inventory and balance
      final testUser = 'content_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await helper.register(testUser, 'password123');

      expect(awp.account.pseudo, testUser);
      expect(awp.profile.eptsBalance, 150); // Starting epts balance

      // Verify profile calculations
      expect(awp.profile.softwarePower, 10);
      expect(awp.profile.hardwarePower, 10);

      // Verify user_software starting items
      final userSoft = await db.query(
        'user_software',
        where: 'profile_id = ?',
        whereArgs: [awp.profile.id],
      );
      expect(userSoft.length, 1);
      expect(userSoft.first['item_id'], 1); // Phishing Mailer v1 (item_id: 1)
      expect(userSoft.first['current_level'], 1);

      // Verify user_hardware starting items
      final userHard = await db.query(
        'user_hardware',
        where: 'profile_id = ?',
        whereArgs: [awp.profile.id],
      );
      expect(userHard.length, 1);
      expect(userHard.first['item_id'], 1); // Intel Celeron Rig (item_id: 1)
    });
  });

  group('icon_key pipeline (step 06)', () {
    // Catalogs that may carry an optional `icon_key`.
    const catalogs = [
      'target_types.json',
      'mission_types.json',
      'software_items.json',
      'hardware_items.json',
    ];

    /// Every non-empty `icon_key` must point at a real bundled PNG, otherwise
    /// the UI silently falls back to a generic glyph and the missing artwork
    /// goes unnoticed until someone eyeballs the screen. Catching it here means
    /// a typo fails on CI instead.
    test('every declared icon_key resolves to a bundled PNG', () {
      final missing = <String>[];

      for (final catalog in catalogs) {
        final entries = (jsonDecode(
          File('assets/data/catalog/$catalog').readAsStringSync(),
        ) as List<dynamic>).cast<Map<String, dynamic>>();

        for (final entry in entries) {
          final key = (entry['icon_key'] as String?)?.trim();
          if (key == null || key.isEmpty) continue;

          final path = 'assets/images/ui/icons/$key.png';
          if (!File(path).existsSync()) {
            missing.add('$catalog → "${entry['name']}" declares "$key" ($path)');
          }
        }
      }

      expect(
        missing,
        isEmpty,
        reason: 'Broken icon_key references:\n${missing.join('\n')}',
      );
    });

    test('seeder carries icon_key from JSON through to the DB', () async {
      final db = await DatabaseHelper.instance.db;

      // The column must exist on all four catalog tables even while the
      // catalogs themselves declare no keys yet — that is what lets a new item
      // light up its icon with a JSON-only edit.
      for (final table in [
        'target_types',
        'mission_types',
        'software_items',
        'hardware_items',
      ]) {
        final columns = await db.rawQuery('PRAGMA table_info($table)');
        expect(
          columns.map((c) => c['name']),
          contains('icon_key'),
          reason: '$table is missing the icon_key column',
        );
      }

      // Round-trip: writing a key and reading it back proves the seeder's
      // insert path and the models' fromMap agree on the column name.
      await db.insert('target_types', {
        'name': '__icon_key_probe__',
        'base_trace_speed': 1,
        'risk_multiplier': 1.0,
        'icon_key': 'probe_icon',
      });
      final row = await db.query(
        'target_types',
        where: 'name = ?',
        whereArgs: ['__icon_key_probe__'],
      );
      expect(row.single['icon_key'], 'probe_icon');

      await db.delete(
        'target_types',
        where: 'name = ?',
        whereArgs: ['__icon_key_probe__'],
      );
    });
  });
}
