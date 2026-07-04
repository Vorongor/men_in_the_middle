import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/game/resolution/resolution_engine.dart';
import 'package:men_in_the_middle/models/profile.dart';
import 'package:men_in_the_middle/repos/inventory_repository.dart';
import 'package:men_in_the_middle/repos/target_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Profile _withWanted(Profile p, int wanted) => Profile(
      id: p.id,
      profileId: p.profileId,
      levelId: p.levelId,
      softwarePower: p.softwarePower,
      hardwarePower: p.hardwarePower,
      rating: p.rating,
      karma: p.karma,
      wanted: wanted,
      popularity: p.popularity,
      blackTrust: p.blackTrust,
      legend: p.legend,
      experience: p.experience,
      eptsBalance: p.eptsBalance,
      uepBalance: p.uepBalance,
    );

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
        }

        if (filePath.isNotEmpty && File(filePath).existsSync()) {
          final bytes = File(filePath).readAsBytesSync();
          return ByteData.sublistView(bytes);
        }
        return null;
      },
    );
  });

  group('Contract Generator Unit Tests', () {
    late DatabaseHelper dbHelper;
    late TargetRepository targetRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_generator_test_${Random().nextInt(0x7FFFFFFF)}.db';
      targetRepo = TargetRepository(dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('1. Auto-generation on register and boundaries validation', () async {
      final pseudo = 'contract_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;

      final contracts = await targetRepo.fetchActiveContracts(profileId);

      // Verify initial contract counts are correct
      expect(contracts.length, greaterThanOrEqualTo(5));
      expect(contracts.length, lessThanOrEqualTo(7));

      for (final c in contracts) {
        expect(c.defense, greaterThanOrEqualTo(1));
        expect(c.eptsReward, greaterThanOrEqualTo(0));
        expect(c.trustReward, greaterThanOrEqualTo(0));
        expect(c.targetRequiredLevel, lessThanOrEqualTo(awp.profile.levelId + 1));
      }
    });

    test('2. Refresh fee payments and budget constraints', () async {
      final pseudo = 'fee_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;

      final db = await dbHelper.db;

      // Set epts_balance to exactly 50 epts
      await db.update('profiles', {'epts_balance': 50}, where: 'id = ?', whereArgs: [profileId]);
      
      final profile = Profile(
        id: awp.profile.id,
        profileId: awp.profile.profileId,
        levelId: awp.profile.levelId,
        softwarePower: awp.profile.softwarePower,
        hardwarePower: awp.profile.hardwarePower,
        rating: awp.profile.rating,
        karma: awp.profile.karma,
        wanted: awp.profile.wanted,
        popularity: awp.profile.popularity,
        blackTrust: awp.profile.blackTrust,
        legend: awp.profile.legend,
        experience: awp.profile.experience,
        eptsBalance: 50,
        uepBalance: awp.profile.uepBalance,
      );

      // Refresh with payFee = true -> succeeds
      await targetRepo.refreshContracts(profile, payFee: true);

      final resProfileMaps = await db.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      final resBalance = resProfileMaps.first['epts_balance'] as int;
      expect(resBalance, 40); // 10 epts deducted

      // Refresh with balance 5 -> throws InsufficientFundsException
      await db.update('profiles', {'epts_balance': 5}, where: 'id = ?', whereArgs: [profileId]);
      
      final profileLow = Profile(
        id: awp.profile.id,
        profileId: awp.profile.profileId,
        levelId: awp.profile.levelId,
        softwarePower: awp.profile.softwarePower,
        hardwarePower: awp.profile.hardwarePower,
        rating: awp.profile.rating,
        karma: awp.profile.karma,
        wanted: awp.profile.wanted,
        popularity: awp.profile.popularity,
        blackTrust: awp.profile.blackTrust,
        legend: awp.profile.legend,
        experience: awp.profile.experience,
        eptsBalance: 5,
        uepBalance: awp.profile.uepBalance,
      );

      expect(
        () => targetRepo.refreshContracts(profileLow, payFee: true),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    test('3. Determinism with seed inputs', () async {
      final pseudo = 'seed_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;

      // Generation with seed = 42
      await targetRepo.refreshContracts(awp.profile, customSeed: 42);
      final contractsSeed42Run1 = await targetRepo.fetchActiveContracts(profileId);

      // Re-generation with seed = 42
      await targetRepo.refreshContracts(awp.profile, customSeed: 42);
      final contractsSeed42Run2 = await targetRepo.fetchActiveContracts(profileId);

      // Re-generation with seed = 99
      await targetRepo.refreshContracts(awp.profile, customSeed: 99);
      final contractsSeed99 = await targetRepo.fetchActiveContracts(profileId);

      expect(contractsSeed42Run1.length, contractsSeed42Run2.length);

      for (int i = 0; i < contractsSeed42Run1.length; i++) {
        expect(contractsSeed42Run1[i].targetTemplateId, contractsSeed42Run2[i].targetTemplateId);
        expect(contractsSeed42Run1[i].defense, contractsSeed42Run2[i].defense);
        expect(contractsSeed42Run1[i].eptsReward, contractsSeed42Run2[i].eptsReward);
      }

      // Check that at least some fields differ with seed 99
      bool differ = false;
      if (contractsSeed42Run1.length != contractsSeed99.length) {
        differ = true;
      } else {
        for (int i = 0; i < contractsSeed42Run1.length; i++) {
          if (contractsSeed42Run1[i].defense != contractsSeed99[i].defense) {
            differ = true;
            break;
          }
        }
      }
      expect(differ, isTrue);
    });

    test('4. No honeypot contracts below the honeypot wanted threshold', () async {
      final pseudo = 'clean_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;

      await targetRepo.refreshContracts(_withWanted(awp.profile, 0), customSeed: 7);
      final contracts = await targetRepo.fetchActiveContracts(profileId);

      expect(contracts.any((c) => c.isHoneypot), isFalse);
    });

    test('5. Exactly one honeypot contract once wanted crosses the threshold', () async {
      final pseudo = 'hot_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;

      await targetRepo.refreshContracts(_withWanted(awp.profile, 60), customSeed: 7);
      final contracts = await targetRepo.fetchActiveContracts(profileId);

      expect(contracts.where((c) => c.isHoneypot).length, 1);
    });

    test('6. ensureCleanUpContract is idempotent and grants no crypto reward', () async {
      final pseudo = 'raided_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;

      final firstId = await targetRepo.ensureCleanUpContract(profileId);
      final secondId = await targetRepo.ensureCleanUpContract(profileId);
      expect(firstId, secondId);

      final details = await targetRepo.fetchContractDetails(firstId);
      expect(details, isNotNull);
      expect(details!.missionTypeId, ResolutionEngine.cleanUpMissionTypeId);
      expect(details.eptsReward, 0);
      expect(details.isHoneypot, isFalse);
    });
  });
}
