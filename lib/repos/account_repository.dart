import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/account_with_profile.dart';

/// Handles login / registration.
/// All crypto and SQL go here; no password logic leaks to UI or state layer.
class AccountRepository {
  const AccountRepository(this._db);
  final DatabaseHelper _db;

  Future<AccountWithProfile?> login(String pseudo, String rawPass) =>
      _db.login(pseudo, rawPass);

  Future<AccountWithProfile> register(String pseudo, String rawPass) =>
      _db.register(pseudo, rawPass);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(DatabaseHelper.instance),
);
