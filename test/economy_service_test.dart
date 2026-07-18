import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/repos/catalog_repository.dart';
import 'package:men_in_the_middle/repos/inventory_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Mock Asset Bundle to read the real files from the workspace (needed for seeder to run)
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

  group('Economy Service unit tests', () {
    late DatabaseHelper dbHelper;
    late CatalogRepository catalogRepo;
    late InventoryRepository inventoryRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_test_${Random().nextInt(0x7FFFFFFF)}.db';
      catalogRepo = CatalogRepository(dbHelper);
      inventoryRepo = InventoryRepository(dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('1. Purchase software success, InsufficientFunds, AlreadyOwned', () async {
      // 1. Register a new profile (starts with 150 epts, has Mailer v1 owned)
      final pseudo = 'eco_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'pass123!');
      final profileId = awp.profile.id!;

      // 2. Fetch catalog software items
      final catalogItems = await catalogRepo.storeItems(awp.profile);
      // Item 4: Brute Force Lite (basePrice: 150 epts)
      final bruteForce = catalogItems.firstWhere((i) => i.id == 4);

      // Attempt to buy with exactly 150 epts -> Success
      await inventoryRepo.buySoftware(profileId, bruteForce);

      // Re-fetch profile to check balance and software power (Celeron 10 + Mailer 10 + Brute Force 12 = 32 power)
      final db = await dbHelper.db;
      final profs = await db.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      expect(profs.first['epts_balance'], 0);
      expect(profs.first['software_power'], 22); // Mailer (10) + Brute Force (12)

      // Verify item exists in user_software
      final ownedSoft = await db.query('user_software', where: 'profile_id = ?', whereArgs: [profileId]);
      expect(ownedSoft.length, 2); // Mailer v1 + Brute Force

      // Attempt to buy another item (e.g. DDoS Botnet v1) when balance is 0 -> Throws InsufficientFundsException
      // Item 7: DDoS Botnet v1 (basePrice: 150 epts)
      final ddos = catalogItems.firstWhere((i) => i.id == 7);
      try {
        await inventoryRepo.buySoftware(profileId, ddos);
        fail('Should have thrown InsufficientFundsException');
      } on InsufficientFundsException catch (_) {
        // Expected
      }

      // Give player more money
      await db.update('profiles', {'epts_balance': 1000}, where: 'id = ?', whereArgs: [profileId]);

      // Attempt to buy Brute Force Lite again -> Throws AlreadyOwnedException
      expect(
        () => inventoryRepo.buySoftware(profileId, bruteForce),
        throwsA(isA<AlreadyOwnedException>()),
      );
    });

    test('2. Software upgrade progression, cost, and max level constraint', () async {
      final pseudo = 'upgrade_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'pass123!');
      final profileId = awp.profile.id!;
      final db = await dbHelper.db;

      // 1. Fetch user owned software (starts with Phishing Mailer v1, user_software id: ?)
      final owned = await inventoryRepo.fetchOwnedSoftware(profileId);
      final mailerWrapper = owned.firstWhere((o) => o.catalogItem.id == 1);
      final userSoftId = mailerWrapper.userSoftware.id!;

      // 2. Set profile epts balance to 500
      await db.update('profiles', {'epts_balance': 500}, where: 'id = ?', whereArgs: [profileId]);

      // Phishing Mailer lvl 1: attack = 10, penetration = 5.
      // Strategy level 2: {"attack": 5, "penetration": 2, "cost": 100}
      await inventoryRepo.upgradeSoftware(profileId, userSoftId);

      // Verify upgraded stats in DB
      final usRows = await db.query('user_software', where: 'id = ?', whereArgs: [userSoftId]);
      final us = usRows.first;
      expect(us['current_level'], 2);
      expect(us['attack'], 15); // 10 + 5
      expect(us['penetration_ability'], 7); // 5 + 2

      // Verify profile balance deducted (500 - 100 = 400)
      final profRows = await db.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      expect(profRows.first['epts_balance'], 400);
      expect(profRows.first['software_power'], 15); // Updated Mailer attack

      // Upgrade until max level (level 5)
      // Level 3 cost: 150
      await inventoryRepo.upgradeSoftware(profileId, userSoftId);
      // Level 4 cost: 220
      await inventoryRepo.upgradeSoftware(profileId, userSoftId);
      // Current level = 4. Remaining balance: 400 - 150 - 220 = 30.
      // Attempting to upgrade to level 5 (cost: 300) -> Throws InsufficientFundsException
      try {
        await inventoryRepo.upgradeSoftware(profileId, userSoftId);
        fail('Should have thrown InsufficientFundsException');
      } on InsufficientFundsException catch (_) {
        // Expected
      }

      // Give more money
      await db.update('profiles', {'epts_balance': 1000}, where: 'id = ?', whereArgs: [profileId]);
      // Upgrade to Level 5 (cost: 300) -> Success
      await inventoryRepo.upgradeSoftware(profileId, userSoftId);

      // Now it is at max level (5). Attempt upgrade to level 6 -> Throws MaxLevelReachedException
      try {
        await inventoryRepo.upgradeSoftware(profileId, userSoftId);
        fail('Should have thrown MaxLevelReachedException');
      } on MaxLevelReachedException catch (_) {
        // Expected
      }
    });
  });
}
