import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/models/attack_log_entry.dart';
import 'package:men_in_the_middle/models/hardware_item.dart';
import 'package:men_in_the_middle/models/mission_type.dart';
import 'package:men_in_the_middle/models/software_item.dart';
import 'package:men_in_the_middle/models/target_template.dart';
import 'package:men_in_the_middle/models/target_type.dart';
import 'package:men_in_the_middle/models/user_hardware.dart';
import 'package:men_in_the_middle/models/user_software.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Model round-trip tests', () {
    test('SoftwareItem round-trip', () {
      final item = SoftwareItem(
        id: 42,
        name: 'Bypass Pro',
        softTypeId: 1,
        description: 'Bypass description',
        basePrice: 500,
        currencyType: 'EPTS',
        reqLevel: 2,
        reqBlackTrust: 10,
        initMaxLevel: 10,
        baseAttack: 5,
        basePenetration: 3,
        baseTrace: 1,
        sockets: 2,
        levelUpStrategy: const {'2': {'attack': 2}},
      );

      final map = item.toMap();
      final decoded = SoftwareItem.fromMap(map);

      expect(decoded.id, 42);
      expect(decoded.name, 'Bypass Pro');
      expect(decoded.softTypeId, 1);
      expect(decoded.description, 'Bypass description');
      expect(decoded.basePrice, 500);
      expect(decoded.currencyType, 'EPTS');
      expect(decoded.reqLevel, 2);
      expect(decoded.reqBlackTrust, 10);
      expect(decoded.initMaxLevel, 10);
      expect(decoded.baseAttack, 5);
      expect(decoded.basePenetration, 3);
      expect(decoded.baseTrace, 1);
      expect(decoded.sockets, 2);
      final strategy2 = decoded.levelUpStrategy['2'] as Map<String, dynamic>;
      expect(strategy2['attack'], 2);
    });

    test('HardwareItem round-trip', () {
      final item = HardwareItem(
        id: 7,
        name: 'Liquid Cool Rig',
        hwType: 'CPU',
        description: 'Cool description',
        basePrice: 1200,
        currencyType: 'UEP',
        reqLevel: 3,
        reqBlackTrust: 50,
        initComputePower: 100,
        initPowerDraw: 20,
        sockets: 3,
      );

      final map = item.toMap();
      final decoded = HardwareItem.fromMap(map);

      expect(decoded.id, 7);
      expect(decoded.name, 'Liquid Cool Rig');
      expect(decoded.hwType, 'CPU');
      expect(decoded.description, 'Cool description');
      expect(decoded.basePrice, 1200);
      expect(decoded.currencyType, 'UEP');
      expect(decoded.reqLevel, 3);
      expect(decoded.reqBlackTrust, 50);
      expect(decoded.initComputePower, 100);
      expect(decoded.initPowerDraw, 20);
      expect(decoded.sockets, 3);
    });

    test('UserSoftware round-trip', () {
      final userSoft = UserSoftware(
        id: 1,
        profileId: 10,
        itemId: 5,
        currentLevel: 2,
        attack: 12,
        penetrationAbility: 8,
        residualTrace: 4,
        modificatorSockets: 2,
      );

      final map = userSoft.toMap();
      final decoded = UserSoftware.fromMap(map);

      expect(decoded.id, 1);
      expect(decoded.profileId, 10);
      expect(decoded.itemId, 5);
      expect(decoded.currentLevel, 2);
      expect(decoded.attack, 12);
      expect(decoded.penetrationAbility, 8);
      expect(decoded.residualTrace, 4);
      expect(decoded.modificatorSockets, 2);
    });

    test('UserHardware round-trip', () {
      final userHard = UserHardware(
        id: 2,
        profileId: 10,
        itemId: 3,
        currentLevel: 1,
        computePower: 45,
        powerDraw: 10,
        modificatorSockets: 1,
      );

      final map = userHard.toMap();
      final decoded = UserHardware.fromMap(map);

      expect(decoded.id, 2);
      expect(decoded.profileId, 10);
      expect(decoded.itemId, 3);
      expect(decoded.currentLevel, 1);
      expect(decoded.computePower, 45);
      expect(decoded.powerDraw, 10);
      expect(decoded.modificatorSockets, 1);
    });

    test('TargetType round-trip', () {
      final type = TargetType(
        id: 3,
        name: 'Cyberpol',
        baseTraceSpeed: 15,
        riskMultiplier: 2.5,
      );

      final map = type.toMap();
      final decoded = TargetType.fromMap(map);

      expect(decoded.id, 3);
      expect(decoded.name, 'Cyberpol');
      expect(decoded.baseTraceSpeed, 15);
      expect(decoded.riskMultiplier, 2.5);
    });

    test('TargetTemplate round-trip', () {
      final temp = TargetTemplate(
        id: 9,
        typeId: 2,
        name: 'Gov Census DB',
        requiredLevel: 4,
        baseDefense: 1500,
        eptsReward: 350,
        trustReward: 15,
        customMechanics: const {'honeypot': true},
      );

      final map = temp.toMap();
      final decoded = TargetTemplate.fromMap(map);

      expect(decoded.id, 9);
      expect(decoded.typeId, 2);
      expect(decoded.name, 'Gov Census DB');
      expect(decoded.requiredLevel, 4);
      expect(decoded.baseDefense, 1500);
      expect(decoded.eptsReward, 350);
      expect(decoded.trustReward, 15);
      expect(decoded.customMechanics['honeypot'], true);
    });

    test('MissionType round-trip', () {
      final mission = MissionType(
        id: 4,
        name: 'DDoS Sabotage',
        description: 'Overload server array',
        primarySoftTypeId: 3,
        baseRewardMult: 1.25,
      );

      final map = mission.toMap();
      final decoded = MissionType.fromMap(map);

      expect(decoded.id, 4);
      expect(decoded.name, 'DDoS Sabotage');
      expect(decoded.description, 'Overload server array');
      expect(decoded.primarySoftTypeId, 3);
      expect(decoded.baseRewardMult, 1.25);
    });

    test('AttackLogEntry round-trip', () {
      final log = AttackLogEntry(
        id: 55,
        profileId: 2,
        targetTemplateId: 8,
        missionTypeId: 1,
        result: 'success',
        eptsDelta: 450,
        wantedDelta: 5,
        trustDelta: 8,
        createdAt: '2026-07-04 10:00:00',
      );

      final map = log.toMap();
      final decoded = AttackLogEntry.fromMap(map);

      expect(decoded.id, 55);
      expect(decoded.profileId, 2);
      expect(decoded.targetTemplateId, 8);
      expect(decoded.missionTypeId, 1);
      expect(decoded.result, 'success');
      expect(decoded.eptsDelta, 450);
      expect(decoded.wantedDelta, 5);
      expect(decoded.trustDelta, 8);
      expect(decoded.createdAt, '2026-07-04 10:00:00');
    });
  });

  group('Database schema check and constraints', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 4,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          // Schema is created automatically via DatabaseHelper instance when accessed.
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Schema tables can be created and checked', () async {
      final helper = DatabaseHelper.instance;
      final realDb = await helper.db;

      final tables = await realDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;");
      final names = tables.map((row) => row['name'] as String).toList();

      expect(names.contains('accounts'), isTrue);
      expect(names.contains('profiles'), isTrue);
      expect(names.contains('levels'), isTrue);
      expect(names.contains('software_types'), isTrue);
      expect(names.contains('target_types'), isTrue);
      expect(names.contains('mission_types'), isTrue);
      expect(names.contains('software_items'), isTrue);
      expect(names.contains('hardware_items'), isTrue);
      expect(names.contains('target_templates'), isTrue);
      expect(names.contains('effectiveness_matrix'), isTrue);
      expect(names.contains('user_software'), isTrue);
      expect(names.contains('user_hardware'), isTrue);
      expect(names.contains('attack_log'), isTrue);
    });

    test('Check constraints: profile wanted BETWEEN 0 AND 100', () async {
      final helper = DatabaseHelper.instance;
      final realDb = await helper.db;

      expect(
        () async => await realDb.insert('profiles', {
          'profile_id': 'CONSTR1',
          'level_id': 1,
          'software_power': 0,
          'hardware_power': 0,
          'rating': 0,
          'karma': 50,
          'wanted': 101,
          'popularity': 0,
          'black_trust': 0,
          'legend': '',
          'experience': 0,
          'epts_balance': 0,
          'uep_balance': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );

      expect(
        () async => await realDb.insert('profiles', {
          'profile_id': 'CONSTR2',
          'level_id': 1,
          'wanted': -1,
          'legend': '',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('Check constraints: json_valid checking', () async {
      final helper = DatabaseHelper.instance;
      final realDb = await helper.db;

      expect(
        () async => await realDb.insert('software_items', {
          'name': 'Bypass Broken',
          'soft_type_id': 1,
          'description': 'broken json test',
          'base_price': 100,
          'currency_type': 'EPTS',
          'req_level': 1,
          'req_black_trust': 0,
          'init_max_level': 5,
          'base_attack': 1,
          'base_penetration': 1,
          'base_trace': 0,
          'sockets': 1,
          'level_up_strategy': 'NOT_A_VALID_JSON',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
