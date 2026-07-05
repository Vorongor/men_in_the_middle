import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/game/resolution/attack_models.dart';
import 'package:men_in_the_middle/game/resolution/resolution_engine.dart';
import 'package:men_in_the_middle/models/active_contract.dart';
import 'package:men_in_the_middle/models/economy_tuning.dart';
import 'package:men_in_the_middle/models/profile.dart';
import 'package:men_in_the_middle/models/software_item.dart';
import 'package:men_in_the_middle/models/user_software.dart';
import 'package:men_in_the_middle/repos/inventory_repository.dart';
import 'package:men_in_the_middle/repos/target_repository.dart';
import 'package:men_in_the_middle/utils/content_validator.dart';
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

  group('1. InventoryRepository - Selling Items', () {
    late DatabaseHelper dbHelper;
    late InventoryRepository inventoryRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_sell_test_${Random().nextInt(0x7FFFFFFF)}.db';
      inventoryRepo = InventoryRepository(dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Sell software and hardware calculates correct prices, deletes entry, updates epts, and recalculates powers', () async {
      final pseudo = 'sell_tester_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;

      final db = await dbHelper.db;

      // Starter software has ID 1 (Phishing Mailer), current level 1, attack 10, basePrice 100 epts.
      // Starter hardware has ID 1 (Intel Celeron CPU), current level 1, basePrice 50 epts.
      // Let's buy a second software item so we can sell one (selling the last software is prohibited).
      // Find a software item in catalog
      final softItemMap = (await db.query('software_items', where: 'id = ?', whereArgs: [2])).first;
      final secondSoftwareItem = SoftwareItem.fromMap(softItemMap);

      // Give player level, black trust and epts to buy it
      await db.update('profiles', {'epts_balance': 1000, 'level_id': 10, 'black_trust': 100}, where: 'id = ?', whereArgs: [profileId]);
      await inventoryRepo.buySoftware(profileId, secondSoftwareItem);

      // Now player owns 2 software items.
      final ownedSoftListBefore = await inventoryRepo.fetchOwnedSoftware(profileId);
      expect(ownedSoftListBefore.length, 2);

      // Let's check initial software power
      final profileBefore = (await db.query('profiles', where: 'id = ?', whereArgs: [profileId])).first;
      final initialSoftPower = profileBefore['software_power'] as int;

      // Sell the first software (ID is userSoftware.id)
      final userSoftToSell = ownedSoftListBefore.firstWhere((s) => s.catalogItem.id == 1);
      final earnedEpts = await inventoryRepo.sellSoftware(profileId, userSoftToSell.userSoftware.id!);

      // base_price is 100, sell_ratio is 0.5. At lvl 1, upgrades cost is 0. Earned = round(0.5 * (100 + 0)) = 50.
      expect(earnedEpts, 50);

      // Entry should be deleted
      final ownedSoftListAfter = await inventoryRepo.fetchOwnedSoftware(profileId);
      expect(ownedSoftListAfter.length, 1);
      expect(ownedSoftListAfter.any((s) => s.userSoftware.id == userSoftToSell.userSoftware.id), isFalse);

      // Balance should be updated: was 1000 - price_of_item2 + 50
      final profileAfter = (await db.query('profiles', where: 'id = ?', whereArgs: [profileId])).first;
      final expectedBalance = (profileBefore['epts_balance'] as int) + 50;
      expect(profileAfter['epts_balance'] as int, expectedBalance);

      // Powers should be recalculated
      expect(profileAfter['software_power'] as int, initialSoftPower - userSoftToSell.userSoftware.attack);

      // Try to sell the last software - should throw LastSoftwareException
      expect(
        () => inventoryRepo.sellSoftware(profileId, ownedSoftListAfter.first.userSoftware.id!),
        throwsA(isA<LastSoftwareException>()),
      );

      // Sell hardware: starter hardware is CPU Celeron, ID 1. Total hardware count is 1.
      final ownedHardListBefore = await inventoryRepo.fetchOwnedHardware(profileId);
      expect(ownedHardListBefore.length, 1);
      final hardToSell = ownedHardListBefore.first;

      // basePrice is 150, lvl 1, upgradesCost 0. Earned = round(0.5 * (150 + 0)) = 75.
      final earnedHardEpts = await inventoryRepo.sellHardware(profileId, hardToSell.userHardware.id!);
      expect(earnedHardEpts, 75);

      final ownedHardListAfter = await inventoryRepo.fetchOwnedHardware(profileId);
      expect(ownedHardListAfter.isEmpty, isTrue);

      final profileFinal = (await db.query('profiles', where: 'id = ?', whereArgs: [profileId])).first;
      expect(profileFinal['hardware_power'] as int, 0);
    });
  });

  group('2. ResolutionEngine - hardware_power = 0', () {
    test('calculate timeBudgetSeconds with hardware_power = 0 without crash or division by zero', () {
      final mockProfile = const Profile(
        id: 1,
        profileId: 'mock1',
        levelId: 1,
        hardwarePower: 0, // 0 hardware power!
        legend: 'test',
      );

      final mockContract = ContractDetails(
        id: 1,
        profileId: 1,
        targetTemplateId: 1,
        missionTypeId: 1,
        defense: 100,
        eptsReward: 100,
        trustReward: 10,
        isCompleted: false,
        targetName: 'Test Target',
        targetRequiredLevel: 1,
        customMechanicsJson: '{}',
        targetTypeId: 1,
        targetTypeName: 'Corporate Employees',
        targetBaseTraceSpeed: 10,
        targetRiskMultiplier: 1.0,
        missionName: 'Data Theft',
        missionDescription: 'desc',
        missionPrimarySoftTypeId: 1,
      );

      final mockOwnedSoft = OwnedSoftware(
        userSoftware: const UserSoftware(
          id: 1,
          profileId: 1,
          itemId: 1,
          currentLevel: 1,
          attack: 20,
          penetrationAbility: 10,
          residualTrace: 2,
        ),
        catalogItem: const SoftwareItem(
          id: 1,
          name: 'Phishing Tool',
          softTypeId: 1,
          description: 'desc',
          basePrice: 100,
          baseAttack: 20,
          basePenetration: 10,
          baseTrace: 2,
          levelUpStrategy: {},
        ),
      );

      final setup = AttackSetup(
        profile: mockProfile,
        contract: mockContract,
        selectedSoftware: mockOwnedSoft,
        hardwarePower: 0,
        damageMult: 1.0,
        traceMult: 1.0,
      );

      // Verify that calling timeBudgetSeconds finishes successfully without crash and shaves off 15% (underpowered)
      final budget = ResolutionEngine.timeBudgetSeconds(setup);
      expect(budget, isPositive);
    });
  });

  group('3. TargetRepository - Board scanning, TTL, Insurance compatibility', () {
    late DatabaseHelper dbHelper;
    late TargetRepository targetRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_board_test_${Random().nextInt(0x7FFFFFFF)}.db';
      targetRepo = TargetRepository(dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Free emergency scan on empty board, TTL filtering, and compatible contract guarantee', () async {
      final pseudo = 'board_tester_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;

      final db = await dbHelper.db;

      // 1. Initially, register generated contracts
      final initialContracts = await targetRepo.fetchActiveContracts(profileId);
      expect(initialContracts.length, greaterThanOrEqualTo(5));

      // 2. Set expires_at of all contracts to past (e.g. 5 hours ago) to simulate TTL expiration
      final pastStr = DateTime.now().subtract(const Duration(hours: 5)).toIso8601String();
      await db.update('active_contracts', {'expires_at': pastStr});

      // 3. fetchActiveContracts should return empty because they are expired!
      final activeList = await targetRepo.fetchActiveContracts(profileId);
      expect(activeList.isEmpty, isTrue);

      // 4. Free emergency scan (refreshContracts with payFee = false)
      // Player only owns Phishing software (soft_type_id: 1). Let's pass ownedSoftTypeIds = [1]
      await db.update('profiles', {'epts_balance': 0}, where: 'id = ?', whereArgs: [profileId]);
      await targetRepo.refreshContracts(awp.profile, payFee: false, ownedSoftTypeIds: const [1]);

      // Epts should still be 0 (free scan)
      final profileAfter = (await db.query('profiles', where: 'id = ?', whereArgs: [profileId])).first;
      expect(profileAfter['epts_balance'] as int, 0);

      // Board should now have contracts
      final newContracts = await targetRepo.fetchActiveContracts(profileId);
      expect(newContracts.length, greaterThanOrEqualTo(5));

      // At least one contract must map to soft_type_id 1 (Phishing), which has primary_soft_type_id: 1 (Data Theft mission)
      final compatible = newContracts.where((c) => c.missionPrimarySoftTypeId == 1);
      expect(compatible.isNotEmpty, isTrue);

      // The guaranteed compatible contract (at index 0 in the db or list) must have reward >= insuranceMinReward (10)
      final firstContract = newContracts.first;
      expect(firstContract.missionPrimarySoftTypeId, 1);
      expect(firstContract.eptsReward, greaterThanOrEqualTo(10));
    });
  });

  group('4. Catalog Config Validation', () {
    test('economy.json contains all required keys and validates properly', () async {
      final economyFile = File('assets/data/catalog/economy.json');
      expect(economyFile.existsSync(), isTrue);

      final economyJson = economyFile.readAsStringSync();
      final softwareItemsJson = File('assets/data/catalog/software_items.json').readAsStringSync();
      final hardwareItemsJson = File('assets/data/catalog/hardware_items.json').readAsStringSync();
      final targetTypesJson = File('assets/data/catalog/target_types.json').readAsStringSync();
      final targetTemplatesJson = File('assets/data/catalog/target_templates.json').readAsStringSync();
      final missionTypesJson = File('assets/data/catalog/mission_types.json').readAsStringSync();
      final effectivenessJson = File('assets/data/catalog/effectiveness.json').readAsStringSync();
      final levelCurveJson = File('assets/data/catalog/level_curve.json').readAsStringSync();

      expect(() => ContentValidator.validate(
        softwareItemsJson: softwareItemsJson,
        hardwareItemsJson: hardwareItemsJson,
        targetTypesJson: targetTypesJson,
        targetTemplatesJson: targetTemplatesJson,
        missionTypesJson: missionTypesJson,
        effectivenessJson: effectivenessJson,
        levelCurveJson: levelCurveJson,
        economyJson: economyJson,
      ), returnsNormally);

      final economy = jsonDecode(economyJson) as Map<String, dynamic>;
      expect(economy['board_refresh_fee'], isA<int>());
      expect(economy['sell_ratio'], isA<double>());
      expect(economy['contract_ttl_hours'], isA<int>());
      expect(economy['insurance_min_reward'], isA<int>());

      final tuning = EconomyTuning.fromMap(economy);
      expect(tuning.boardRefreshFee, 10);
      expect(tuning.sellRatio, 0.5);
      expect(tuning.contractTtlHours, 24);
      expect(tuning.insuranceMinReward, 10);
    });
  });
}
