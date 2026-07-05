import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/economy_tuning.dart';
import '../models/hardware_item.dart';
import '../models/software_item.dart';
import '../models/user_hardware.dart';
import '../models/user_software.dart';
import '../utils/wanted_effects.dart';

// ── Custom Exceptions ────────────────────────────────────────────────────────

sealed class EconomyException implements Exception {
  final String message;
  const EconomyException(this.message);
  @override
  String toString() => message;
}

class InsufficientFundsException extends EconomyException {
  const InsufficientFundsException() : super('Insufficient funds.');
}

class RequirementsNotMetException extends EconomyException {
  const RequirementsNotMetException(super.message);
}

class AlreadyOwnedException extends EconomyException {
  const AlreadyOwnedException() : super('You already own this item.');
}

class MaxLevelReachedException extends EconomyException {
  const MaxLevelReachedException() : super('Item is already at maximum level.');
}

class LastSoftwareException extends EconomyException {
  const LastSoftwareException() : super('Cannot sell your last software tool. You need at least one tool to perform attacks.');
}

// ── Repository ───────────────────────────────────────────────────────────────

/// Handles queries and modifications for the player's software/hardware inventory.
class InventoryRepository {
  final DatabaseHelper _db;
  const InventoryRepository(this._db);

  /// Fetches all software items owned by the given player profile.
  Future<List<OwnedSoftware>> fetchOwnedSoftware(int profileId) async {
    final d = await _db.db;
    final List<Map<String, dynamic>> maps = await d.rawQuery('''
      SELECT 
        us.id AS us_id, us.profile_id, us.item_id, us.current_level, us.attack, us.penetration_ability, us.residual_trace, us.modificator_sockets,
        si.id AS si_id, si.name, si.soft_type_id, si.description, si.base_price, si.currency_type, si.req_level, si.req_black_trust, si.init_max_level, si.base_attack, si.base_penetration, si.base_trace, si.sockets, si.level_up_strategy
      FROM user_software us
      JOIN software_items si ON us.item_id = si.id
      WHERE us.profile_id = ?
    ''', [profileId]);
    
    return maps.map((row) {
      final userSoft = UserSoftware(
        id: row['us_id'] as int,
        profileId: row['profile_id'] as int,
        itemId: row['item_id'] as int,
        currentLevel: row['current_level'] as int,
        attack: row['attack'] as int,
        penetrationAbility: row['penetration_ability'] as int,
        residualTrace: row['residual_trace'] as int,
        modificatorSockets: row['modificator_sockets'] as int,
      );
      final catalogItem = SoftwareItem(
        id: row['si_id'] as int,
        name: row['name'] as String,
        softTypeId: row['soft_type_id'] as int,
        description: row['description'] as String,
        basePrice: row['base_price'] as int,
        currencyType: row['currency_type'] as String,
        reqLevel: row['req_level'] as int,
        reqBlackTrust: row['req_black_trust'] as int,
        initMaxLevel: row['init_max_level'] as int,
        baseAttack: row['base_attack'] as int,
        basePenetration: row['base_penetration'] as int,
        baseTrace: row['base_trace'] as int,
        sockets: row['sockets'] as int,
        levelUpStrategy: SoftwareItem.fromMap(row).levelUpStrategy,
      );
      return OwnedSoftware(userSoftware: userSoft, catalogItem: catalogItem);
    }).toList();
  }

  /// Fetches all hardware items owned by the given player profile.
  Future<List<OwnedHardware>> fetchOwnedHardware(int profileId) async {
    final d = await _db.db;
    final List<Map<String, dynamic>> maps = await d.rawQuery('''
      SELECT 
        uh.id AS uh_id, uh.profile_id, uh.item_id, uh.current_level, uh.compute_power, uh.power_draw, uh.modificator_sockets,
        hi.id AS hi_id, hi.name, hi.hw_type, hi.description, hi.base_price, hi.currency_type, hi.req_level, hi.req_black_trust, hi.init_compute_power, hi.init_power_draw, hi.sockets
      FROM user_hardware uh
      JOIN hardware_items hi ON uh.item_id = hi.id
      WHERE uh.profile_id = ?
    ''', [profileId]);
    
    return maps.map((row) {
      final userHard = UserHardware(
        id: row['uh_id'] as int,
        profileId: row['profile_id'] as int,
        itemId: row['item_id'] as int,
        currentLevel: row['current_level'] as int,
        computePower: row['compute_power'] as int,
        powerDraw: row['power_draw'] as int,
        modificatorSockets: row['modificator_sockets'] as int,
      );
      final catalogItem = HardwareItem(
        id: row['hi_id'] as int,
        name: row['name'] as String,
        hwType: row['hw_type'] as String,
        description: row['description'] as String,
        basePrice: row['base_price'] as int,
        currencyType: row['currency_type'] as String,
        reqLevel: row['req_level'] as int,
        reqBlackTrust: row['req_black_trust'] as int,
        initComputePower: row['init_compute_power'] as int,
        initPowerDraw: row['init_power_draw'] as int,
        sockets: row['sockets'] as int,
      );
      return OwnedHardware(userHardware: userHard, catalogItem: catalogItem);
    }).toList();
  }

  /// Purchases a software item inside a transaction.
  /// Deducts EPTS balance and recalculates total software power.
  Future<void> buySoftware(int profileId, SoftwareItem item) async {
    final d = await _db.db;
    await d.transaction((txn) async {
      // 1. Fetch current profile state
      final profileMaps = await txn.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      if (profileMaps.isEmpty) throw Exception('Profile not found');
      final pMap = profileMaps.first;
      
      final currentEpts = pMap['epts_balance'] as int;
      final currentLevel = pMap['level_id'] as int;
      final currentTrust = pMap['black_trust'] as int;
      final currentWanted = pMap['wanted'] as int;
      final price = WantedEffects.effectivePrice(item.basePrice, currentWanted);

      // 2. Check requirements
      if (currentLevel < item.reqLevel) {
        throw RequirementsNotMetException('Level ${item.reqLevel} required.');
      }
      if (currentTrust < item.reqBlackTrust) {
        throw RequirementsNotMetException('Black trust ${item.reqBlackTrust} required.');
      }
      if (currentEpts < price) {
        throw const InsufficientFundsException();
      }

      // 3. Check if already owned
      final ownedMaps = await txn.query(
        'user_software',
        where: 'profile_id = ? AND item_id = ?',
        whereArgs: [profileId, item.id],
      );
      if (ownedMaps.isNotEmpty) {
        throw const AlreadyOwnedException();
      }

      // 4. Insert into inventory
      await txn.insert('user_software', {
        'profile_id': profileId,
        'item_id': item.id,
        'current_level': 1,
        'attack': item.baseAttack,
        'penetration_ability': item.basePenetration,
        'residual_trace': item.baseTrace,
        'modificator_sockets': item.sockets,
      });

      // 5. Deduct balance (risk-tax-adjusted price, not the sticker price)
      await txn.update(
        'profiles',
        {'epts_balance': currentEpts - price},
        where: 'id = ?',
        whereArgs: [profileId],
      );

      // 6. Recalculate powers
      await _recalculatePowersTxn(txn, profileId);
    });
  }

  /// Purchases a hardware item inside a transaction.
  /// Deducts EPTS balance and recalculates total hardware power.
  Future<void> buyHardware(int profileId, HardwareItem item) async {
    final d = await _db.db;
    await d.transaction((txn) async {
      // 1. Fetch current profile state
      final profileMaps = await txn.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      if (profileMaps.isEmpty) throw Exception('Profile not found');
      final pMap = profileMaps.first;

      final currentEpts = pMap['epts_balance'] as int;
      final currentLevel = pMap['level_id'] as int;
      final currentTrust = pMap['black_trust'] as int;
      final currentWanted = pMap['wanted'] as int;
      final price = WantedEffects.effectivePrice(item.basePrice, currentWanted);

      // 2. Check requirements
      if (currentLevel < item.reqLevel) {
        throw RequirementsNotMetException('Level ${item.reqLevel} required.');
      }
      if (currentTrust < item.reqBlackTrust) {
        throw RequirementsNotMetException('Black trust ${item.reqBlackTrust} required.');
      }
      if (currentEpts < price) {
        throw const InsufficientFundsException();
      }

      // 3. Check if already owned
      final ownedMaps = await txn.query(
        'user_hardware',
        where: 'profile_id = ? AND item_id = ?',
        whereArgs: [profileId, item.id],
      );
      if (ownedMaps.isNotEmpty) {
        throw const AlreadyOwnedException();
      }

      // 4. Insert into inventory
      await txn.insert('user_hardware', {
        'profile_id': profileId,
        'item_id': item.id,
        'current_level': 1,
        'compute_power': item.initComputePower,
        'power_draw': item.initPowerDraw,
        'modificator_sockets': item.sockets,
      });

      // 5. Deduct balance (risk-tax-adjusted price, not the sticker price)
      await txn.update(
        'profiles',
        {'epts_balance': currentEpts - price},
        where: 'id = ?',
        whereArgs: [profileId],
      );

      // 6. Recalculate powers
      await _recalculatePowersTxn(txn, profileId);
    });
  }

  /// Upgrades a software item. Cost and increments are retrieved from the strategy template.
  Future<void> upgradeSoftware(int profileId, int userSoftId) async {
    final d = await _db.db;
    await d.transaction((txn) async {
      // 1. Fetch user_software entry
      final usMaps = await txn.query('user_software', where: 'id = ?', whereArgs: [userSoftId]);
      if (usMaps.isEmpty) throw Exception('Owned software not found');
      final us = UserSoftware.fromMap(usMaps.first);

      // 2. Fetch catalog item
      final catalogMaps = await txn.query('software_items', where: 'id = ?', whereArgs: [us.itemId]);
      if (catalogMaps.isEmpty) throw Exception('Catalog item not found');
      final catalog = SoftwareItem.fromMap(catalogMaps.first);

      // 3. Check if max level reached
      if (us.currentLevel >= catalog.initMaxLevel) {
        throw const MaxLevelReachedException();
      }

      // 4. Get strategy step for the next level
      final nextLvl = us.currentLevel + 1;
      final strategyStep = catalog.levelUpStrategy[nextLvl.toString()] as Map<String, dynamic>?;
      if (strategyStep == null) {
        throw Exception('Level up strategy not found for level $nextLvl');
      }

      final cost = strategyStep['cost'] as int;
      final attackBonus = strategyStep['attack'] as int? ?? 0;
      final penetrationBonus = strategyStep['penetration'] as int? ?? 0;

      // 5. Fetch profile balance
      final profileMaps = await txn.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      final pMap = profileMaps.first;
      final currentEpts = pMap['epts_balance'] as int;


      if (currentEpts < cost) {
        throw const InsufficientFundsException();
      }

      // 6. Update user_software stats
      await txn.update(
        'user_software',
        {
          'current_level': nextLvl,
          'attack': us.attack + attackBonus,
          'penetration_ability': us.penetrationAbility + penetrationBonus,
        },
        where: 'id = ?',
        whereArgs: [userSoftId],
      );

      // 7. Deduct balance
      await txn.update(
        'profiles',
        {'epts_balance': currentEpts - cost},
        where: 'id = ?',
        whereArgs: [profileId],
      );

      // 8. Recalculate powers
      await _recalculatePowersTxn(txn, profileId);
    });
  }

  /// Upgrades a hardware item using default scaling formulas.
  Future<void> upgradeHardware(int profileId, int userHardId) async {
    final d = await _db.db;
    await d.transaction((txn) async {
      // 1. Fetch user_hardware entry
      final uhMaps = await txn.query('user_hardware', where: 'id = ?', whereArgs: [userHardId]);
      if (uhMaps.isEmpty) throw Exception('Owned hardware not found');
      final uh = UserHardware.fromMap(uhMaps.first);

      // 2. Fetch catalog item
      final catalogMaps = await txn.query('hardware_items', where: 'id = ?', whereArgs: [uh.itemId]);
      if (catalogMaps.isEmpty) throw Exception('Catalog item not found');
      final catalog = HardwareItem.fromMap(catalogMaps.first);

      // 3. Max level check
      const maxLvl = 5;
      if (uh.currentLevel >= maxLvl) {
        throw const MaxLevelReachedException();
      }

      // 4. Calculate upgrade cost and stat gains using default formulas
      final nextLvl = uh.currentLevel + 1;
      final cost = (catalog.basePrice * 0.6 * uh.currentLevel).round();
      final powerBonus = (catalog.initComputePower * 0.25).round();

      // 5. Fetch profile balance
      final profileMaps = await txn.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      final pMap = profileMaps.first;
      final currentEpts = pMap['epts_balance'] as int;

      if (currentEpts < cost) {
        throw const InsufficientFundsException();
      }

      // 6. Update user_hardware stats
      await txn.update(
        'user_hardware',
        {
          'current_level': nextLvl,
          'compute_power': uh.computePower + powerBonus,
        },
        where: 'id = ?',
        whereArgs: [userHardId],
      );

      // 7. Deduct balance
      await txn.update(
        'profiles',
        {'epts_balance': currentEpts - cost},
        where: 'id = ?',
        whereArgs: [profileId],
      );

      // 8. Recalculate powers
      await _recalculatePowersTxn(txn, profileId);
    });
  }

  /// Sells a software item inside a transaction.
  /// Returns the earned epts amount.
  Future<int> sellSoftware(int profileId, int userSoftId) async {
    final d = await _db.db;
    return d.transaction((txn) async {
      // 1. Fetch current profile state
      final profileMaps = await txn.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      if (profileMaps.isEmpty) throw Exception('Profile not found');
      final currentEpts = profileMaps.first['epts_balance'] as int;

      // 2. Fetch all user software owned by this profile to guard against selling the last one
      final ownedSoftMaps = await txn.query('user_software', where: 'profile_id = ?', whereArgs: [profileId]);
      if (ownedSoftMaps.length <= 1) {
        throw const LastSoftwareException();
      }

      // 3. Fetch specific user software entry
      final usMaps = await txn.query('user_software', where: 'id = ? AND profile_id = ?', whereArgs: [userSoftId, profileId]);
      if (usMaps.isEmpty) throw Exception('Owned software not found');
      final us = UserSoftware.fromMap(usMaps.first);

      // 4. Fetch catalog item
      final catalogMaps = await txn.query('software_items', where: 'id = ?', whereArgs: [us.itemId]);
      if (catalogMaps.isEmpty) throw Exception('Catalog item not found');
      final catalog = SoftwareItem.fromMap(catalogMaps.first);

      // 5. Load Economy Tuning
      final tuningMaps = await txn.query('meta', where: 'key = ?', whereArgs: ['economy_tuning']);
      final tuning = tuningMaps.isNotEmpty
          ? EconomyTuning.fromMap(jsonDecode(tuningMaps.first['value'] as String) as Map<String, dynamic>)
          : const EconomyTuning(boardRefreshFee: 10, sellRatio: 0.5, contractTtlHours: 24, insuranceMinReward: 10);

      // 6. Calculate sell price
      int upgradesCost = 0;
      for (int l = 2; l <= us.currentLevel; l++) {
        final step = catalog.levelUpStrategy[l.toString()] as Map<String, dynamic>?;
        if (step != null) {
          upgradesCost += step['cost'] as int? ?? 0;
        }
      }
      final sellPrice = (tuning.sellRatio * (catalog.basePrice + upgradesCost)).round();

      // 7. Delete from user_software
      await txn.delete('user_software', where: 'id = ?', whereArgs: [userSoftId]);

      // 8. Update profile balance
      await txn.update(
        'profiles',
        {'epts_balance': currentEpts + sellPrice},
        where: 'id = ?',
        whereArgs: [profileId],
      );

      // 9. Recalculate powers
      await _recalculatePowersTxn(txn, profileId);

      return sellPrice;
    });
  }

  /// Sells a hardware item inside a transaction.
  /// Returns the earned epts amount.
  Future<int> sellHardware(int profileId, int userHardId) async {
    final d = await _db.db;
    return d.transaction((txn) async {
      // 1. Fetch current profile state
      final profileMaps = await txn.query('profiles', where: 'id = ?', whereArgs: [profileId]);
      if (profileMaps.isEmpty) throw Exception('Profile not found');
      final currentEpts = profileMaps.first['epts_balance'] as int;

      // 2. Fetch specific user hardware entry
      final uhMaps = await txn.query('user_hardware', where: 'id = ? AND profile_id = ?', whereArgs: [userHardId, profileId]);
      if (uhMaps.isEmpty) throw Exception('Owned hardware not found');
      final uh = UserHardware.fromMap(uhMaps.first);

      // 3. Fetch catalog item
      final catalogMaps = await txn.query('hardware_items', where: 'id = ?', whereArgs: [uh.itemId]);
      if (catalogMaps.isEmpty) throw Exception('Catalog item not found');
      final catalog = HardwareItem.fromMap(catalogMaps.first);

      // 4. Load Economy Tuning
      final tuningMaps = await txn.query('meta', where: 'key = ?', whereArgs: ['economy_tuning']);
      final tuning = tuningMaps.isNotEmpty
          ? EconomyTuning.fromMap(jsonDecode(tuningMaps.first['value'] as String) as Map<String, dynamic>)
          : const EconomyTuning(boardRefreshFee: 10, sellRatio: 0.5, contractTtlHours: 24, insuranceMinReward: 10);

      // 5. Calculate sell price
      int upgradesCost = 0;
      for (int lvl = 1; lvl < uh.currentLevel; lvl++) {
        upgradesCost += (catalog.basePrice * 0.6 * lvl).round();
      }
      final sellPrice = (tuning.sellRatio * (catalog.basePrice + upgradesCost)).round();

      // 6. Delete from user_hardware
      await txn.delete('user_hardware', where: 'id = ?', whereArgs: [userHardId]);

      // 7. Update profile balance
      await txn.update(
        'profiles',
        {'epts_balance': currentEpts + sellPrice},
        where: 'id = ?',
        whereArgs: [profileId],
      );

      // 8. Recalculate powers
      await _recalculatePowersTxn(txn, profileId);

      return sellPrice;
    });
  }

  /// Recalculates calculated software and hardware power stats.
  Future<void> _recalculatePowersTxn(Transaction txn, int profileId) async {
    final softSumMaps = await txn.rawQuery(
      'SELECT SUM(attack) as total FROM user_software WHERE profile_id = ?',
      [profileId],
    );
    final totalSoftPower = softSumMaps.first['total'] as int? ?? 0;

    final hardSumMaps = await txn.rawQuery(
      'SELECT SUM(compute_power) as total FROM user_hardware WHERE profile_id = ?',
      [profileId],
    );
    final totalHardPower = hardSumMaps.first['total'] as int? ?? 0;

    await txn.update(
      'profiles',
      {
        'software_power': totalSoftPower,
        'hardware_power': totalHardPower,
      },
      where: 'id = ?',
      whereArgs: [profileId],
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(DatabaseHelper.instance),
);
