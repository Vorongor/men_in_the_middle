import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account_with_profile.dart';
import '../repos/account_repository.dart';
import '../repos/profile_repository.dart';

import '../utils/async_value_ext.dart';

/// Holds the current authenticated player's data.
/// null = not logged in.
class PlayerSessionNotifier
    extends Notifier<AsyncValue<AccountWithProfile?>> {
  @override
  AsyncValue<AccountWithProfile?> build() => const AsyncValue.data(null);

  AccountRepository get _accountRepo => ref.read(accountRepositoryProvider);
  ProfileRepository get _profileRepo => ref.read(profileRepositoryProvider);

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Authenticates an existing account. Returns false on wrong credentials.
  Future<bool> login(String pseudo, String rawPass) async {
    state = const AsyncValue.loading();
    try {
      final result = await _accountRepo.login(pseudo, rawPass);
      state = AsyncValue.data(result);
      return result != null;
    } catch (e, st) {
      state = AsyncValue<AccountWithProfile?>.error(e, st);
      return false;
    }
  }

  /// Creates a new account and immediately starts a session.
  Future<void> register(String pseudo, String rawPass) async {
    state = const AsyncValue.loading();
    try {
      final result = await _accountRepo.register(pseudo, rawPass);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue<AccountWithProfile?>.error(e, st);
    }
  }

  /// Clears the current session (logout).
  void logout() => state = const AsyncValue.data(null);

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Re-reads the profile from DB and updates the in-memory state.
  /// Call after any mutation that went directly to the repo.
  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      final updated =
          await _profileRepo.fetchAccountWithProfile(current.account.id!);
      if (updated != null) state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue<AccountWithProfile?>.error(e, st);
    }
  }

  /// Applies a delta to numeric profile fields without a full DB round-trip.
  /// Persists the change to the DB then updates state from the refreshed row.
  Future<void> updateProfileFields(Map<String, int> deltas) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _profileRepo.applyDeltas(current.profile.id!, deltas);
    await refresh();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// The single source of truth for the logged-in player.
///
/// Usage in widgets:
/// ```dart
/// final session = ref.watch(playerSessionProvider);
/// session.when(
///   data: (awp) { ... },
///   loading: () { ... },
///   error: (e, _) { ... },
/// );
/// ```
final playerSessionProvider =
    NotifierProvider<PlayerSessionNotifier, AsyncValue<AccountWithProfile?>>(
  PlayerSessionNotifier.new,
);
