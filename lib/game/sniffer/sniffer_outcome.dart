import '../resolution/attack_models.dart';
import 'sniffer_config.dart';

/// Converts raw in-game counters into the shared [MinigameOutcome] the
/// Resolution Engine expects. Kept separate from [SnifferGame] so the
/// grading rule is unit-testable without spinning up Flame's game loop.
class SnifferOutcomeCalculator {
  const SnifferOutcomeCalculator._();

  static MinigameOutcome compute({
    required SnifferConfig config,
    required int caughtGreen,
    required int redHits,
    required double timeRemainingSeconds,
  }) {
    final success =
        caughtGreen >= config.targetCatches && redHits <= config.allowedRedHits;
    if (!success) {
      return const MinigameOutcome(success: false, timeRatio: 0.0);
    }
    final ratio = config.timeBudgetSeconds <= 0
        ? 0.0
        : (timeRemainingSeconds / config.timeBudgetSeconds).clamp(0.0, 1.0).toDouble();
    return MinigameOutcome(success: true, timeRatio: ratio);
  }
}
