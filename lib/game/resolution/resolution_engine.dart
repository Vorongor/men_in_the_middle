import '../../utils/wanted_effects.dart';
import 'attack_models.dart';

/// Pure Dart attack grading. No Flutter, no DB — every formula here is a
/// plain function of its inputs so it can be unit-tested without a widget
/// tree or a database.
///
/// Scenarios (see docs/game_concept.md "Система Нагород та Покарань"):
/// - Honeypot: always fails with an elevated wanted penalty, regardless of
///   the minigame outcome — the trap sprung the moment the attack launched.
/// - Clean Up Traces: a special mission that trades its (zero) crypto payout
///   for a flat wanted reduction on success, instead of the usual rewards.
/// - Ideal hack (success, timeRatio > 0.5): full epts + full exp + black_trust,
///   a small passive wanted cooldown, small chance of a bonus drop.
/// - Hard hack (success, timeRatio <= 0.5): full epts + full exp, but a flat
///   wanted penalty (traces were left behind).
/// - Fail: no reward, wanted penalty scaled by how much of a mismatch the
///   chosen software was for this target (damage/trace multipliers) and by
///   how dangerous the target class is (risk_multiplier).
class ResolutionEngine {
  const ResolutionEngine._();

  /// Baseline countdown, seconds. Prep/Attack screens use this only for the
  /// difficulty preview; the actual minigame timer arrives in Step 08.
  static const int baseTimeSeconds = 30;

  /// Flat wanted penalty for a "hard" success or the multiplier base for a
  /// failure. Tunable in Step 10 balancing without touching call sites.
  static const int baseWantedGain = 5;

  /// Chance of a bonus drop on an ideal hack.
  static const double dropChance = 0.15;

  /// Multiplies [baseWantedGain] for a sprung honeypot — getting caught in a
  /// trap should sting far more than a routine failed attack.
  static const int honeypotWantedMultiplier = 3;

  /// `mission_types.id` for "Clean Up Traces" (seeded in
  /// assets/data/catalog/mission_types.json). Hardcoded to match the
  /// existing convention of literal mission/soft-type ids used throughout
  /// this codebase (e.g. Attack Screen's Phishing check).
  static const int cleanUpMissionTypeId = 5;

  /// Software attack after applying the soft-type-vs-target-type multiplier.
  static int effectiveAttack(AttackSetup setup) =>
      (setup.selectedSoftware.userSoftware.attack * setup.damageMult).round();

  /// Effective attack power ratio relative to defense.
  static double powerRatio(AttackSetup setup) {
    final defense = setup.contract.defense;
    if (defense <= 0) return 0.0;
    return effectiveAttack(setup) / defense;
  }

  /// Calculates trace risk score for the prep preview.
  static double traceRisk(AttackSetup setup) {
    return setup.traceMult * setup.selectedSoftware.userSoftware.residualTrace;
  }

  /// Suggested countdown for the minigame, in seconds. Stronger effective
  /// attack and higher penetration shrink the target's effective defense;
  /// being under-equipped on hardware shaves a further penalty off the top.
  static int timeBudgetSeconds(AttackSetup setup) {
    final penetration = setup.selectedSoftware.userSoftware.penetrationAbility;
    final adjustedDefense = setup.contract.defense / (1 + penetration / 100);
    final powerRatio = adjustedDefense <= 0
        ? 2.5
        : effectiveAttack(setup) / adjustedDefense;
    final clampedRatio = powerRatio.clamp(0.4, 2.5);
    final underpowered = setup.hardwarePower < setup.contract.defense / 2;
    final hardwarePenalty = underpowered ? 0.85 : 1.0;
    return (baseTimeSeconds * clampedRatio * hardwarePenalty).round();
  }

  /// Grades a finished attack. [dropRoll] is an externally supplied 0..1
  /// random sample (default 1.0 = "never drops") so the function stays
  /// deterministic and testable; callers pass `Random().nextDouble()`.
  static AttackResolution resolve(
    AttackSetup setup,
    MinigameOutcome outcome, {
    double dropRoll = 1.0,
  }) {
    final contract = setup.contract;

    if (contract.isHoneypot) {
      final wantedGain =
          (baseWantedGain * honeypotWantedMultiplier * contract.targetRiskMultiplier)
              .round();
      return AttackResolution(
        result: AttackResultKind.fail,
        eptsDelta: 0,
        expDelta: 0,
        wantedDelta: wantedGain,
        trustDelta: 0,
      );
    }

    if (!outcome.success) {
      final wantedGain =
          (baseWantedGain * contract.targetRiskMultiplier * setup.traceMult)
              .round();
      return AttackResolution(
        result: AttackResultKind.fail,
        eptsDelta: 0,
        expDelta: 0,
        wantedDelta: wantedGain,
        trustDelta: 0,
      );
    }

    // Difficulty-scaled XP: tougher targets teach more, independent of the
    // crypto payout so wanted/econ balancing can move separately from XP.
    final baseExp = (contract.defense * 0.6).round();

    if (contract.missionTypeId == cleanUpMissionTypeId) {
      return AttackResolution(
        result: AttackResultKind.success,
        eptsDelta: 0,
        expDelta: baseExp,
        wantedDelta: -WantedEffects.cleanUpReduction,
        trustDelta: 0,
      );
    }

    if (outcome.perfect) {
      final drops = dropRoll < dropChance
          ? const ['Bonus payload: supplier discount voucher acquired.']
          : const <String>[];
      return AttackResolution(
        result: AttackResultKind.success,
        eptsDelta: contract.eptsReward,
        expDelta: baseExp,
        wantedDelta: -WantedEffects.passiveCooldown,
        trustDelta: contract.trustReward,
        drops: drops,
      );
    }

    return AttackResolution(
      result: AttackResultKind.hard,
      eptsDelta: contract.eptsReward,
      expDelta: baseExp,
      wantedDelta: baseWantedGain,
      trustDelta: 0,
    );
  }
}
