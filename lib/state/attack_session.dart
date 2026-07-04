import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/resolution/attack_models.dart';
import '../game/resolution/resolution_engine.dart';
import '../repos/attack_repository.dart';
import 'player_session.dart';

/// Ephemeral state for a single attack run: prepared setup → minigame
/// outcome → graded resolution → persisted result.
///
/// Living in a provider (instead of route arguments) means Attack Prep,
/// Attack and Attack Result all see the same setup without re-fetching or
/// re-deriving it, and a completed attack can't be re-applied by rebuilds.
class AttackSessionState {
  final AttackSetup? setup;
  final MinigameOutcome? outcome;
  final AttackResolution? resolution;
  final bool applied;
  final AttackApplyResult? applyResult;

  const AttackSessionState({
    this.setup,
    this.outcome,
    this.resolution,
    this.applied = false,
    this.applyResult,
  });

  AttackSessionState copyWith({
    AttackSetup? setup,
    MinigameOutcome? outcome,
    AttackResolution? resolution,
    bool? applied,
    AttackApplyResult? applyResult,
  }) =>
      AttackSessionState(
        setup: setup ?? this.setup,
        outcome: outcome ?? this.outcome,
        resolution: resolution ?? this.resolution,
        applied: applied ?? this.applied,
        applyResult: applyResult ?? this.applyResult,
      );
}

class AttackSessionNotifier extends Notifier<AttackSessionState> {
  @override
  AttackSessionState build() => const AttackSessionState();

  /// Called from Attack Prep once the player picks software and launches.
  void start(AttackSetup setup) {
    state = AttackSessionState(setup: setup);
  }

  /// Called from Attack once the (stubbed) minigame reports an outcome.
  /// Grades it immediately so the Result screen only needs to persist and
  /// display, not compute.
  void resolve(MinigameOutcome outcome, {double dropRoll = 1.0}) {
    final setup = state.setup;
    if (setup == null) return;
    final resolution = ResolutionEngine.resolve(setup, outcome, dropRoll: dropRoll);
    state = state.copyWith(outcome: outcome, resolution: resolution);
  }

  /// Persists the resolution and refreshes the player session. Safe to call
  /// more than once (e.g. on a rebuild) — only the first call has an effect.
  Future<void> applyAndRefreshSession() async {
    if (state.applied) return;
    final setup = state.setup;
    final resolution = state.resolution;
    if (setup == null || resolution == null) return;

    final result = await ref.read(attackRepositoryProvider).applyResolution(
          profileId: setup.profile.id!,
          contractId: setup.contract.id,
          targetTemplateId: setup.contract.targetTemplateId,
          missionTypeId: setup.contract.missionTypeId,
          resolution: resolution,
        );

    state = state.copyWith(applied: true, applyResult: result);
    await ref.read(playerSessionProvider.notifier).refresh();
  }

  /// Clears the session once the player leaves the result screen, so the
  /// next attack starts clean.
  void reset() => state = const AttackSessionState();
}

final attackSessionProvider =
    NotifierProvider<AttackSessionNotifier, AttackSessionState>(
  AttackSessionNotifier.new,
);
