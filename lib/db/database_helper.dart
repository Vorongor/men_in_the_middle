import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/account_with_profile.dart';
import '../models/level.dart';
import '../models/profile.dart';
import '../utils/legend_loader.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'middlemen.db'),
      version: _dbVersion,
      onCreate: (db, _) => _createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) => _migrate(db),
    );
  }

  Future<void> _migrate(Database db) async {
    // Dev-stage: wipe and recreate on any version change
    await db.execute('DROP TABLE IF EXISTS accounts');
    await db.execute('DROP TABLE IF EXISTS profiles');
    await db.execute('DROP TABLE IF EXISTS levels');
    await _createSchema(db);
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE IF NOT EXISTS levels (
        id          INTEGER PRIMARY KEY,
        name        TEXT    NOT NULL,
        description TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS profiles (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        level_id        INTEGER NOT NULL DEFAULT 1 REFERENCES levels(id),
        software_power  INTEGER NOT NULL DEFAULT 0,
        hardware_power  INTEGER NOT NULL DEFAULT 0,
        rating          INTEGER NOT NULL DEFAULT 0,
        karma           INTEGER NOT NULL DEFAULT 50
                        CHECK(karma       BETWEEN 1 AND 100),
        wanted          INTEGER NOT NULL DEFAULT 1
                        CHECK(wanted      BETWEEN 1 AND 100),
        popularity      INTEGER NOT NULL DEFAULT 0,
        black_trust     INTEGER NOT NULL DEFAULT 1
                        CHECK(black_trust BETWEEN 1 AND 100),
        legend          TEXT    NOT NULL DEFAULT '',
        experience      INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        pseudo     TEXT    NOT NULL UNIQUE,
        pass       TEXT    NOT NULL,
        profile_id INTEGER NOT NULL REFERENCES profiles(id)
      )
    ''');

    _seedLevels(batch);

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

  Future<AccountWithProfile?> login(String pseudo, String passHash) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT
        a.id         AS id,
        a.pseudo     AS pseudo,
        a.pass       AS pass,
        a.profile_id AS profile_id,
        p.id             AS p_id,
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
        l.id             AS level_id,
        l.name           AS level_name,
        l.description    AS level_desc
      FROM accounts a
      JOIN profiles p ON p.id = a.profile_id
      JOIN levels   l ON l.id = p.level_id
      WHERE a.pseudo = ? AND a.pass = ?
    ''', [pseudo, passHash]);

    if (rows.isEmpty) return null;
    return _rowToAccountWithProfile(rows.first);
  }

  Future<AccountWithProfile> register(String pseudo, String passHash) async {
    final legend = await pickRandomLegend();
    final d = await db;

    final profileId = await d.insert(
      'profiles',
      Profile(levelId: 1, legend: legend).toMap(),
    );

    final accountId = await d.insert('accounts', {
      'pseudo': pseudo,
      'pass': passHash,
      'profile_id': profileId,
    });

    return _fetchAccountWithProfile(d, accountId);
  }

  Future<AccountWithProfile> _fetchAccountWithProfile(
      Database d, int accountId) async {
    final rows = await d.rawQuery('''
      SELECT
        a.id         AS id,
        a.pseudo     AS pseudo,
        a.pass       AS pass,
        a.profile_id AS profile_id,
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
        l.name           AS level_name,
        l.description    AS level_desc
      FROM accounts a
      JOIN profiles p ON p.id = a.profile_id
      JOIN levels   l ON l.id = p.level_id
      WHERE a.id = ?
    ''', [accountId]);

    return _rowToAccountWithProfile(rows.first);
  }

  AccountWithProfile _rowToAccountWithProfile(Map<String, dynamic> r) {
    final account = Account(
      id: r['id'] as int,
      pseudo: r['pseudo'] as String,
      pass: r['pass'] as String,
      profileId: r['profile_id'] as int,
    );
    final profile = Profile(
      id: r['profile_id'] as int,
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
    );
    final level = Level(
      id: r['level_id'] as int,
      name: r['level_name'] as String,
      description: r['level_desc'] as String,
    );
    return AccountWithProfile(account: account, profile: profile, level: level);
  }
}
