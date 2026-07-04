import '../resolution/attack_models.dart';
import '../resolution/resolution_engine.dart';

int _clampInt(num v, int lo, int hi) => v.clamp(lo, hi).toInt();
double _clampDouble(num v, double lo, double hi) => v.clamp(lo, hi).toDouble();

/// Difficulty parameters for the "Data Sniffer" (Перехоплення потоку)
/// minigame, derived once from an [AttackSetup].
///
/// Pure Dart — no Flame, no Flutter — so it can be unit-tested without a
/// widget tree or game loop, per docs/planning/step_08.
class SnifferConfig {
  /// Starting countdown, seconds (reuses the Resolution Engine's formula so
  /// Attack Prep's preview and the actual minigame always agree).
  final int timeBudgetSeconds;

  /// Green packets that must be caught to win.
  final int targetCatches;

  /// Multiplier on the paddle's base width. Higher software attack -> wider
  /// paddle -> easier to catch, per the concept doc.
  final double paddleWidthFactor;

  /// Red packets the player may hit before it counts as a failure.
  final int allowedRedHits;

  /// Packet fall speed, logical px/s.
  final double fallSpeed;

  /// Fraction of spawned packets that are red (0..1).
  final double redRatio;

  /// Fraction of red packets that spawn disguised as green ("chameleon"),
  /// revealing their true color shortly before reaching the paddle.
  final double chameleonChance;

  /// Seconds between packet spawns.
  final double spawnIntervalSeconds;

  const SnifferConfig({
    required this.timeBudgetSeconds,
    required this.targetCatches,
    required this.paddleWidthFactor,
    required this.allowedRedHits,
    required this.fallSpeed,
    required this.redRatio,
    required this.chameleonChance,
    required this.spawnIntervalSeconds,
  });

  factory SnifferConfig.fromSetup(AttackSetup setup) {
    final attack = setup.selectedSoftware.userSoftware.attack;
    final penetration = setup.selectedSoftware.userSoftware.penetrationAbility;
    final defense = setup.contract.defense;

    return SnifferConfig(
      timeBudgetSeconds: ResolutionEngine.timeBudgetSeconds(setup),
      targetCatches: _clampInt(7 + defense / 45, 6, 20),
      paddleWidthFactor: _clampDouble(1.0 + attack / 80, 0.8, 2.2),
      allowedRedHits: _clampInt(attack / 20, 0, 3),
      fallSpeed: _clampDouble(
        (110 + defense * 0.35) / (1 + penetration / 120),
        60,
        420,
      ),
      redRatio: _clampDouble(0.32 - penetration / 500, 0.15, 0.32),
      // "Пакет-хамелеон" only shows up once a target is tough enough to
      // count as at least MEDIUM difficulty.
      chameleonChance: defense >= 150 ? 0.3 : 0.0,
      spawnIntervalSeconds: _clampDouble(0.85 - defense / 2200, 0.35, 0.85),
    );
  }
}
