import '../../models/active_contract.dart';
import '../../models/profile.dart';
import '../../models/user_software.dart';

/// Everything the resolution engine needs to grade an attack.
///
/// [damageMult] / [traceMult] come from `effectiveness_matrix` for the pair
/// (selected software's soft type, contract's target type). They are looked
/// up by the caller (DB access) so this whole `game/resolution` module stays
/// a pure, DB- and Flutter-free layer.
class AttackSetup {
  final Profile profile;
  final ContractDetails contract;
  final OwnedSoftware selectedSoftware;
  final int hardwarePower;
  final double damageMult;
  final double traceMult;

  const AttackSetup({
    required this.profile,
    required this.contract,
    required this.selectedSoftware,
    required this.hardwarePower,
    required this.damageMult,
    required this.traceMult,
  });
}

/// Outcome of the (currently stubbed) hacking minigame.
///
/// [perfect] is derived rather than stored: an attack can only be "clean" if
/// it also succeeded, so keeping it as a separate field would let the two
/// disagree. Threshold matches the concept doc's "Ideal hack" scenario.
class MinigameOutcome {
  final bool success;

  /// Fraction of the timer left when the minigame ended, 0..1.
  final double timeRatio;

  const MinigameOutcome({required this.success, required this.timeRatio});

  bool get perfect => success && timeRatio > 0.5;
}

/// Maps 1:1 to the `attack_log.result` CHECK constraint.
enum AttackResultKind { success, hard, fail }

extension AttackResultKindDb on AttackResultKind {
  String get dbValue => switch (this) {
        AttackResultKind.success => 'success',
        AttackResultKind.hard => 'hard',
        AttackResultKind.fail => 'fail',
      };
}

/// Consequences of a resolved attack, ready to be persisted by
/// [AttackRepository]. All deltas are relative; clamping against profile
/// bounds (wanted/black_trust 0..100) happens at apply time, not here.
class AttackResolution {
  final AttackResultKind result;
  final int eptsDelta;
  final int expDelta;
  final int wantedDelta;
  final int trustDelta;
  final List<String> drops;

  const AttackResolution({
    required this.result,
    required this.eptsDelta,
    required this.expDelta,
    required this.wantedDelta,
    required this.trustDelta,
    this.drops = const [],
  });
}
