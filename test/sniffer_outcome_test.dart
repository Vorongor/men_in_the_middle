// Pure unit tests: no Flutter binding, no Flame game loop.
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/game/sniffer/sniffer_config.dart';
import 'package:men_in_the_middle/game/sniffer/sniffer_outcome.dart';

const _config = SnifferConfig(
  timeBudgetSeconds: 30,
  targetCatches: 10,
  paddleWidthFactor: 1.2,
  allowedRedHits: 1,
  fallSpeed: 160,
  redRatio: 0.25,
  chameleonChance: 0.0,
  spawnIntervalSeconds: 0.6,
);

void main() {
  group('SnifferOutcomeCalculator.compute — success', () {
    test('enough catches and hits within budget succeeds with a time ratio', () {
      final outcome = SnifferOutcomeCalculator.compute(
        config: _config,
        caughtGreen: 10,
        redHits: 0,
        timeRemainingSeconds: 15,
      );
      expect(outcome.success, isTrue);
      expect(outcome.timeRatio, closeTo(0.5, 1e-9));
    });

    test('exactly at the allowed red hit boundary still succeeds', () {
      final outcome = SnifferOutcomeCalculator.compute(
        config: _config,
        caughtGreen: 10,
        redHits: 1, // allowedRedHits == 1
        timeRemainingSeconds: 10,
      );
      expect(outcome.success, isTrue);
    });

    test('overshooting the catch target still succeeds', () {
      final outcome = SnifferOutcomeCalculator.compute(
        config: _config,
        caughtGreen: 15,
        redHits: 0,
        timeRemainingSeconds: 5,
      );
      expect(outcome.success, isTrue);
    });

    test('time ratio is clamped to 1.0 even if remaining exceeds the budget', () {
      final outcome = SnifferOutcomeCalculator.compute(
        config: _config,
        caughtGreen: 10,
        redHits: 0,
        timeRemainingSeconds: 999,
      );
      expect(outcome.timeRatio, 1.0);
    });

    test('a zero time budget still grades success but reports a zero ratio', () {
      const zeroBudget = SnifferConfig(
        timeBudgetSeconds: 0,
        targetCatches: 5,
        paddleWidthFactor: 1.0,
        allowedRedHits: 0,
        fallSpeed: 100,
        redRatio: 0.2,
        chameleonChance: 0.0,
        spawnIntervalSeconds: 0.5,
      );
      final outcome = SnifferOutcomeCalculator.compute(
        config: zeroBudget,
        caughtGreen: 5,
        redHits: 0,
        timeRemainingSeconds: 0,
      );
      expect(outcome.success, isTrue);
      expect(outcome.timeRatio, 0.0);
    });
  });

  group('SnifferOutcomeCalculator.compute — failure', () {
    test('one catch short of the target fails even with time and hits to spare', () {
      final outcome = SnifferOutcomeCalculator.compute(
        config: _config,
        caughtGreen: 9,
        redHits: 0,
        timeRemainingSeconds: 20,
      );
      expect(outcome.success, isFalse);
      expect(outcome.timeRatio, 0.0);
    });

    test('one red hit past the allowance fails even with all catches made', () {
      final outcome = SnifferOutcomeCalculator.compute(
        config: _config,
        caughtGreen: 10,
        redHits: 2, // allowedRedHits == 1
        timeRemainingSeconds: 20,
      );
      expect(outcome.success, isFalse);
      expect(outcome.timeRatio, 0.0);
    });

    test('failure always reports a zero time ratio regardless of time left', () {
      final outcome = SnifferOutcomeCalculator.compute(
        config: _config,
        caughtGreen: 0,
        redHits: 5,
        timeRemainingSeconds: 29,
      );
      expect(outcome.success, isFalse);
      expect(outcome.timeRatio, 0.0);
    });
  });
}
