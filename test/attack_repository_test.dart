import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/game/resolution/attack_models.dart';
import 'package:men_in_the_middle/repos/attack_repository.dart';
import 'package:men_in_the_middle/repos/target_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

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
        } else if (key.contains('legends.json')) {
          filePath = 'assets/data/legends.json';
        } else if (key.contains('economy.json')) {
          filePath = 'assets/data/catalog/economy.json';
        }

        if (filePath.isNotEmpty && File(filePath).existsSync()) {
          final bytes = File(filePath).readAsBytesSync();
          return ByteData.sublistView(bytes);
        }
        return null;
      },
    );
  });

  group('AttackRepository.applyResolution', () {
    late DatabaseHelper dbHelper;
    late AttackRepository attackRepo;
    late TargetRepository targetRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_attack_test_${Random().nextInt(0x7FFFFFFF)}.db';
      attackRepo = AttackRepository(dbHelper);
      targetRepo = TargetRepository(dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    Future<(int profileId, int contractId, int targetTemplateId, int missionTypeId)>
        registerWithContract(String pseudo) async {
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;
      final contracts = await targetRepo.fetchActiveContracts(profileId);
      final c = contracts.first;
      return (profileId, c.id, c.targetTemplateId, c.missionTypeId);
    }

    test('1. Hard success: epts/exp/wanted applied, contract completed, log written', () async {
      final pseudo = 'atk_hard_${Random().nextInt(0x7FFFFFFF)}';
      final (profileId, contractId, templateId, missionId) =
          await registerWithContract(pseudo);

      final result = await attackRepo.applyResolution(
        profileId: profileId,
        contractId: contractId,
        targetTemplateId: templateId,
        missionTypeId: missionId,
        resolution: const AttackResolution(
          result: AttackResultKind.hard,
          eptsDelta: 300,
          expDelta: 50,
          wantedDelta: 5,
          trustDelta: 0,
        ),
      );

      expect(result.leveledUp, isFalse);

      final db = await dbHelper.db;
      final profileRows = await db.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      final p = profileRows.first;
      // Starter balance is 150 epts.
      expect(p['epts_balance'], 150 + 300);
      expect(p['experience'], 50);
      expect(p['wanted'], 5);
      expect(p['black_trust'], 0);

      final contractRows =
          await db.query('active_contracts', where: 'id = ?', whereArgs: [contractId]);
      expect(contractRows.first['is_completed'], 1);

      final logRows =
          await db.query('attack_log', where: 'profile_id = ?', whereArgs: [profileId]);
      expect(logRows.length, 1);
      expect(logRows.first['result'], 'hard');
      expect(logRows.first['epts_delta'], 300);
    });

    test('2. Ideal success grants black_trust, fail grants none', () async {
      final pseudo = 'atk_ideal_${Random().nextInt(0x7FFFFFFF)}';
      final (profileId, contractId, templateId, missionId) =
          await registerWithContract(pseudo);

      await attackRepo.applyResolution(
        profileId: profileId,
        contractId: contractId,
        targetTemplateId: templateId,
        missionTypeId: missionId,
        resolution: const AttackResolution(
          result: AttackResultKind.success,
          eptsDelta: 200,
          expDelta: 40,
          wantedDelta: 0,
          trustDelta: 8,
        ),
      );

      final db = await dbHelper.db;
      final p = (await db.query('profiles', where: 'id = ?', whereArgs: [profileId])).first;
      expect(p['black_trust'], 8);
      expect(p['wanted'], 0);
    });

    test('3. Wanted clamps at 100 instead of violating the CHECK constraint', () async {
      final pseudo = 'atk_clamp_${Random().nextInt(0x7FFFFFFF)}';
      final (profileId, contractId, templateId, missionId) =
          await registerWithContract(pseudo);

      final db = await dbHelper.db;
      await db.update('profiles', {'wanted': 98}, where: 'id = ?', whereArgs: [profileId]);

      // Should not throw even though 98 + 15 > 100.
      await attackRepo.applyResolution(
        profileId: profileId,
        contractId: contractId,
        targetTemplateId: templateId,
        missionTypeId: missionId,
        resolution: const AttackResolution(
          result: AttackResultKind.fail,
          eptsDelta: 0,
          expDelta: 0,
          wantedDelta: 15,
          trustDelta: 0,
        ),
      );

      final p = (await db.query('profiles', where: 'id = ?', whereArgs: [profileId])).first;
      expect(p['wanted'], 100);
    });

    test('4. Crossing a level_curve threshold updates level_id and reports the new name', () async {
      final pseudo = 'atk_lvl_${Random().nextInt(0x7FFFFFFF)}';
      final (profileId, contractId, templateId, missionId) =
          await registerWithContract(pseudo);

      // level_curve.json: level 2 requires 100 exp; starter profile has 0.
      final result = await attackRepo.applyResolution(
        profileId: profileId,
        contractId: contractId,
        targetTemplateId: templateId,
        missionTypeId: missionId,
        resolution: const AttackResolution(
          result: AttackResultKind.success,
          eptsDelta: 0,
          expDelta: 150,
          wantedDelta: 0,
          trustDelta: 0,
        ),
      );

      expect(result.leveledUp, isTrue);
      expect(result.newLevelId, 2);
      expect(result.newLevelName, 'Squirrel');

      final db = await dbHelper.db;
      final p = (await db.query('profiles', where: 'id = ?', whereArgs: [profileId])).first;
      expect(p['level_id'], 2);
    });

    test('5. Small exp gain below the next threshold does not level up', () async {
      final pseudo = 'atk_nolvl_${Random().nextInt(0x7FFFFFFF)}';
      final (profileId, contractId, templateId, missionId) =
          await registerWithContract(pseudo);

      final result = await attackRepo.applyResolution(
        profileId: profileId,
        contractId: contractId,
        targetTemplateId: templateId,
        missionTypeId: missionId,
        resolution: const AttackResolution(
          result: AttackResultKind.hard,
          eptsDelta: 10,
          expDelta: 20,
          wantedDelta: 1,
          trustDelta: 0,
        ),
      );

      expect(result.leveledUp, isFalse);
      expect(result.newLevelId, isNull);
    });
  });
}
