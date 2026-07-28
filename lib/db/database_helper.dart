import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/account.dart';
import '../models/account_with_profile.dart';
import '../models/level.dart';
import '../models/profile.dart';
import '../repos/target_repository.dart';
import '../utils/legend_loader.dart';
import '../utils/password_hasher.dart';
import '../utils/profile_id_generator.dart';
import 'content_seeder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  /// v7 — added `icon_key` to the four catalog tables (step 06).
  static const _dbVersion = 7;

  String dbName = 'middlemen.db';
  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<Database> _initDb() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      join(dbPath, dbName),
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) => _createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) => _migrate(db),
    );
    // Seed content after DB is ready (updates content catalogs from assets)
    await ContentSeeder.seed(database);
    return database;
  }

  Future<void> _migrate(Database db) async {
    await db.execute('DROP TABLE IF EXISTS meta');
    await db.execute('DROP TABLE IF EXISTS active_contracts');
    await db.execute('DROP TABLE IF EXISTS attack_log');
    await db.execute('DROP TABLE IF EXISTS user_hardware');
    await db.execute('DROP TABLE IF EXISTS user_software');
    await db.execute('DROP TABLE IF EXISTS effectiveness_matrix');
    await db.execute('DROP TABLE IF EXISTS target_templates');
    await db.execute('DROP TABLE IF EXISTS hardware_items');
    await db.execute('DROP TABLE IF EXISTS software_items');
    await db.execute('DROP TABLE IF EXISTS target_types');
    await db.execute('DROP TABLE IF EXISTS mission_types');
    await db.execute('DROP TABLE IF EXISTS software_types');
    await db.execute('DROP TABLE IF EXISTS accounts');
    await db.execute('DROP TABLE IF EXISTS profiles');
    await db.execute('DROP TABLE IF EXISTS levels');
    await _createSchema(db);
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS levels (
        id          INTEGER PRIMARY KEY,
        name        TEXT    NOT NULL UNIQUE,
        description TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS profiles (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id      TEXT    NOT NULL UNIQUE,
        level_id        INTEGER NOT NULL DEFAULT 1 REFERENCES levels(id),
        software_power  INTEGER NOT NULL DEFAULT 0,
        hardware_power  INTEGER NOT NULL DEFAULT 0,
        rating          INTEGER NOT NULL DEFAULT 0 CHECK(rating >= 0),
        karma           INTEGER NOT NULL DEFAULT 50 CHECK(karma BETWEEN 1 AND 100),
        wanted          INTEGER NOT NULL DEFAULT 0 CHECK(wanted BETWEEN 0 AND 100),
        popularity      INTEGER NOT NULL DEFAULT 0,
        black_trust     INTEGER NOT NULL DEFAULT 0 CHECK(black_trust BETWEEN 0 AND 100),
        legend          TEXT    NOT NULL DEFAULT '',
        experience      INTEGER NOT NULL DEFAULT 0 CHECK(experience >= 0),
        epts_balance    INTEGER NOT NULL DEFAULT 0 CHECK(epts_balance >= 0),
        uep_balance     INTEGER NOT NULL DEFAULT 0 CHECK(uep_balance >= 0)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        pseudo     TEXT    NOT NULL UNIQUE,
        pass       TEXT    NOT NULL,
        salt       TEXT    NOT NULL,
        profile_id INTEGER NOT NULL REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS software_types (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT    NOT NULL UNIQUE
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS target_types (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT    NOT NULL UNIQUE,
        base_trace_speed INTEGER NOT NULL CHECK(base_trace_speed >= 1),
        risk_multiplier  REAL    NOT NULL CHECK(risk_multiplier >= 0),
        icon_key         TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS mission_types (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        name                 TEXT    NOT NULL UNIQUE,
        description          TEXT    NOT NULL,
        primary_soft_type_id INTEGER NOT NULL REFERENCES software_types(id),
        base_reward_mult     REAL    NOT NULL DEFAULT 1.0 CHECK(base_reward_mult >= 0),
        icon_key             TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS software_items (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        name              TEXT    NOT NULL UNIQUE,
        soft_type_id      INTEGER NOT NULL REFERENCES software_types(id),
        description       TEXT    NOT NULL,
        base_price        INTEGER NOT NULL CHECK(base_price >= 0),
        currency_type     TEXT    NOT NULL DEFAULT 'EPTS' CHECK(currency_type IN ('EPTS', 'UEP')),
        req_level         INTEGER NOT NULL DEFAULT 1 REFERENCES levels(id),
        req_black_trust   INTEGER NOT NULL DEFAULT 0 CHECK(req_black_trust BETWEEN 0 AND 100),
        init_max_level    INTEGER NOT NULL DEFAULT 5 CHECK(init_max_level >= 1),
        base_attack       INTEGER NOT NULL CHECK(base_attack >= 1),
        base_penetration  INTEGER NOT NULL CHECK(base_penetration >= 1),
        base_trace        INTEGER NOT NULL CHECK(base_trace >= 0),
        sockets           INTEGER NOT NULL DEFAULT 1 CHECK(sockets >= 1),
        level_up_strategy TEXT    NOT NULL CHECK(json_valid(level_up_strategy)),
        icon_key          TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS hardware_items (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        name               TEXT    NOT NULL UNIQUE,
        hw_type            TEXT    NOT NULL CHECK(hw_type IN ('CPU', 'RAM', 'NET', 'GPU', 'IO')),
        description        TEXT    NOT NULL,
        base_price         INTEGER NOT NULL CHECK(base_price >= 0),
        currency_type      TEXT    NOT NULL DEFAULT 'EPTS' CHECK(currency_type IN ('EPTS', 'UEP')),
        req_level          INTEGER NOT NULL DEFAULT 1 REFERENCES levels(id),
        req_black_trust    INTEGER NOT NULL DEFAULT 0 CHECK(req_black_trust BETWEEN 0 AND 100),
        init_compute_power INTEGER NOT NULL CHECK(init_compute_power >= 1),
        init_power_draw    INTEGER NOT NULL CHECK(init_power_draw >= 0),
        sockets            INTEGER NOT NULL DEFAULT 1 CHECK(sockets >= 1),
        icon_key           TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS target_templates (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        type_id          INTEGER NOT NULL REFERENCES target_types(id),
        name             TEXT    NOT NULL UNIQUE,
        required_level   INTEGER NOT NULL DEFAULT 1 REFERENCES levels(id),
        base_defense     INTEGER NOT NULL CHECK(base_defense >= 1),
        epts_reward      INTEGER NOT NULL CHECK(epts_reward >= 0),
        trust_reward     INTEGER NOT NULL CHECK(trust_reward >= 0),
        custom_mechanics TEXT    NOT NULL CHECK(json_valid(custom_mechanics))
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS effectiveness_matrix (
        soft_type_id   INTEGER NOT NULL REFERENCES software_types(id),
        target_type_id INTEGER NOT NULL REFERENCES target_types(id),
        damage_mult    REAL    NOT NULL DEFAULT 1.0 CHECK(damage_mult >= 0),
        trace_mult     REAL    NOT NULL DEFAULT 1.0 CHECK(trace_mult >= 0),
        PRIMARY KEY (soft_type_id, target_type_id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS user_software (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id          INTEGER NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        item_id             INTEGER NOT NULL REFERENCES software_items(id),
        current_level       INTEGER NOT NULL DEFAULT 1 CHECK(current_level >= 1),
        attack              INTEGER NOT NULL CHECK(attack >= 1),
        penetration_ability INTEGER NOT NULL CHECK(penetration_ability >= 1),
        residual_trace      INTEGER NOT NULL CHECK(residual_trace >= 0),
        modificator_sockets INTEGER NOT NULL DEFAULT 1 CHECK(modificator_sockets >= 1),
        UNIQUE(profile_id, item_id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS user_hardware (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id          INTEGER NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        item_id             INTEGER NOT NULL REFERENCES hardware_items(id),
        current_level       INTEGER NOT NULL DEFAULT 1 CHECK(current_level >= 1),
        compute_power       INTEGER NOT NULL CHECK(compute_power >= 1),
        power_draw          INTEGER NOT NULL CHECK(power_draw >= 0),
        modificator_sockets INTEGER NOT NULL DEFAULT 1 CHECK(modificator_sockets >= 1),
        UNIQUE(profile_id, item_id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS attack_log (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id         INTEGER NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        target_template_id INTEGER NOT NULL REFERENCES target_templates(id),
        mission_type_id    INTEGER NOT NULL REFERENCES mission_types(id),
        result             TEXT    NOT NULL CHECK(result IN ('success', 'hard', 'fail')),
        epts_delta         INTEGER NOT NULL,
        wanted_delta       INTEGER NOT NULL,
        trust_delta        INTEGER NOT NULL,
        created_at         TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS active_contracts (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id         INTEGER NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
        target_template_id INTEGER NOT NULL REFERENCES target_templates(id),
        mission_type_id    INTEGER NOT NULL REFERENCES mission_types(id),
        defense            INTEGER NOT NULL CHECK(defense >= 1),
        epts_reward        INTEGER NOT NULL CHECK(epts_reward >= 0),
        trust_reward       INTEGER NOT NULL CHECK(trust_reward >= 0),
        expires_at         TEXT,
        is_completed       INTEGER NOT NULL DEFAULT 0 CHECK(is_completed IN (0, 1)),
        is_honeypot        INTEGER NOT NULL DEFAULT 0 CHECK(is_honeypot IN (0, 1))
      )
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_user_software_profile ON user_software(profile_id)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_user_hardware_profile ON user_hardware(profile_id)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_attack_log_profile ON attack_log(profile_id)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_active_contracts_profile ON active_contracts(profile_id)
    ''');

    _seedLevels(batch);
    _seedSoftwareTypes(batch);

    await batch.commit(noResult: true);
  }

  void _seedLevels(Batch batch) {
    const levels = [
      (1, 'Mouse',     'Start. The smallest, avoids dangers.'),
      (2, 'Squirrel',  'Fast, but still very vulnerable.'),
      (3, 'Hare',      'More agile, able to escape from problems.'),
      (4, 'Marten',    'First transition to small predators.'),
      (5, 'Raccoon',   'The golden mean: cunning, smart, adapts to everything.'),
      (6, 'Badger',    'A more serious and hardy beast that can stand up for itself.'),
      (7, 'Fox',       'Smart, dangerous and fast hunter.'),
      (8, 'Lynx',      'A stealthy and deadly predator of a higher order.'),
      (9, 'Wolverine', 'An extremely aggressive and fearless beast, feared even by larger animals.'),
      (10, 'Wolf',     'The pinnacle of this ecosystem. The leader.'),
    ];
    for (final (id, name, desc) in levels) {
      batch.insert('levels', {'id': id, 'name': name, 'description': desc});
    }
  }

  void _seedSoftwareTypes(Batch batch) {
    const types = ['Phishing', 'Bruteforce', 'DDoS', 'Exploit'];
    for (var i = 0; i < types.length; i++) {
      batch.insert('software_types', {'id': i + 1, 'name': types[i]});
    }
  }

  /// Single joined projection used by both login, register **and repos**,
  /// so the three flows can never drift apart.
  /// Public so [ProfileRepository] can reuse it without duplicating SQL.
  static const joinedSelect = '''
    SELECT
      a.id             AS id,
      a.pseudo         AS pseudo,
      a.pass           AS pass,
      a.salt           AS salt,
      a.profile_id     AS profile_db_id,
      p.profile_id     AS profile_display_id,
      p.level_id       AS level_id,
      p.software_power AS software_power,
      p.hardware_power AS hardware_power,
      p.rating         AS rating,
      p.karma          AS karma,
      p.wanted         AS wanted,
      p.popularity     AS popularity,
      p.black_trust    AS black_trust,
      p.legend         AS legend,
      p.experience     AS experience,
      p.epts_balance   AS epts_balance,
      p.uep_balance    AS uep_balance,
      l.name           AS level_name,
      l.description    AS level_desc
    FROM accounts a
    JOIN profiles p ON p.id = a.profile_id
    JOIN levels   l ON l.id = p.level_id
  ''';

  /// Returns the account on success, null on unknown pseudo or wrong password.
  Future<AccountWithProfile?> login(String pseudo, String rawPass) async {
    final d = await db;
    final rows =
        await d.rawQuery('$joinedSelect WHERE a.pseudo = ?', [pseudo]);
    if (rows.isEmpty) return null;

    final row = rows.first;
    final ok = PasswordHasher.verify(
      rawPass,
      row['salt'] as String,
      row['pass'] as String,
    );
    if (!ok) return null;

    return rowToAccountWithProfile(row);
  }

  Future<AccountWithProfile> register(String pseudo, String rawPass) async {
    final legend = await pickRandomLegend();
    final salt = PasswordHasher.generateSalt();
    final passHash = PasswordHasher.hash(rawPass, salt);
    final displayId = generateProfileId();

    final d = await db;
    final accountId = await d.transaction((txn) async {
      final profileId = await txn.insert(
        'profiles',
        Profile(
          profileId: displayId,
          levelId: 1,
          legend: legend,
          eptsBalance: 150, // Starter balance: 150 epts
        ).toMap(),
      );

      // Starter inventory: 1 Phishing Mailer v1 (item_id: 1)
      await txn.insert('user_software', {
        'profile_id': profileId,
        'item_id': 1,
        'current_level': 1,
        'attack': 10,
        'penetration_ability': 5,
        'residual_trace': 2,
        'modificator_sockets': 1,
      });

      // Starter inventory: 1 Intel Celeron CPU Rig (item_id: 1)
      await txn.insert('user_hardware', {
        'profile_id': profileId,
        'item_id': 1,
        'current_level': 1,
        'compute_power': 10,
        'power_draw': 5,
        'modificator_sockets': 1,
      });

      // Set initial profile calculated software_power and hardware_power
      await txn.update(
        'profiles',
        {
          'software_power': 10,
          'hardware_power': 10,
        },
        where: 'id = ?',
        whereArgs: [profileId],
      );

      return txn.insert('accounts', {
        'pseudo': pseudo,
        'pass': passHash,
        'salt': salt,
        'profile_id': profileId,
      });
    });

    final rows =
        await d.rawQuery('$joinedSelect WHERE a.id = ?', [accountId]);
    final accountWithProfile = rowToAccountWithProfile(rows.first);

    // Initial contract board generation
    final targetRepo = TargetRepository(this);
    await targetRepo.refreshContracts(accountWithProfile.profile, ownedSoftTypeIds: const [1]);

    return accountWithProfile;
  }

  /// Maps a raw DB row (from [joinedSelect]) to [AccountWithProfile].
  /// Public so repos can build the model without going through DatabaseHelper
  /// methods.
  static AccountWithProfile rowToAccountWithProfile(Map<String, dynamic> r) {
    final account = Account(
      id: r['id'] as int,
      pseudo: r['pseudo'] as String,
      pass: r['pass'] as String,
      profileId: r['profile_db_id'] as int,
    );
    final profile = Profile(
      id: r['profile_db_id'] as int,
      profileId: r['profile_display_id'] as String,
      levelId: r['level_id'] as int,
      softwarePower: r['software_power'] as int,
      hardwarePower: r['hardware_power'] as int,
      rating: r['rating'] as int,
      karma: r['karma'] as int,
      wanted: r['wanted'] as int,
      popularity: r['popularity'] as int,
      blackTrust: r['black_trust'] as int,
      legend: r['legend'] as String,
      experience: r['experience'] as int,
      eptsBalance: r['epts_balance'] as int,
      uepBalance: r['uep_balance'] as int,
    );
    final level = Level(
      id: r['level_id'] as int,
      name: r['level_name'] as String,
      description: r['level_desc'] as String,
    );
    return AccountWithProfile(account: account, profile: profile, level: level);
  }
}
