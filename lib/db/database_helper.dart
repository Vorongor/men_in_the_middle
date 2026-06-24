import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'middlemen.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE accounts (
          id     INTEGER PRIMARY KEY AUTOINCREMENT,
          pseudo TEXT    NOT NULL UNIQUE,
          pass   TEXT    NOT NULL
        )
      '''),
    );
  }

  Future<Account?> login(String pseudo, String passHash) async {
    final rows = await (await db).query(
      'accounts',
      where: 'pseudo = ? AND pass = ?',
      whereArgs: [pseudo, passHash],
    );
    return rows.isEmpty ? null : Account.fromMap(rows.first);
  }

  Future<Account> register(String pseudo, String passHash) async {
    final id = await (await db).insert(
      'accounts',
      Account(pseudo: pseudo, pass: passHash).toMap(),
    );
    return Account(id: id, pseudo: pseudo, pass: passHash);
  }
}
