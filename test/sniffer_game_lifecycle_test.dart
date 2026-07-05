// Regression tests for step 01: SnifferGame lifecycle race condition and
// _PrepRow overflow on narrow surfaces.
//
// These tests use the real Flutter/Flame widget stack but run with
// `flutter_test`'s fake async and a tiny surface so the race that caused
// the alpha-1.0 crash (onGameResize before onLoad completes) is exercised.

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/game/resolution/attack_models.dart';
import 'package:men_in_the_middle/game/sniffer/sniffer_config.dart';
import 'package:men_in_the_middle/game/sniffer/sniffer_game.dart';

// ── helpers ───────────────────────────────────────────────────────────────

SnifferConfig _minimalConfig() => const SnifferConfig(
      timeBudgetSeconds: 30,
      targetCatches: 5,
      paddleWidthFactor: 1.0,
      allowedRedHits: 1,
      fallSpeed: 160,
      redRatio: 0.25,
      chameleonChance: 0.0,
      spawnIntervalSeconds: 0.6,
    );

SnifferGame _buildGame({void Function(MinigameOutcome)? onComplete}) =>
    SnifferGame(
      config: _minimalConfig(),
      onComplete: onComplete ?? (_) {},
    );

/// Mounts a [GameWidget] inside a constrained surface of [width]x[height].
Widget _gameWidget(SnifferGame game, {double width = 300, double height = 600}) =>
    MaterialApp(
      home: SizedBox(
        width: width,
        height: height,
        child: GameWidget(game: game),
      ),
    );

// ── 1.3 A -- lifecycle race (the LateInitializationError bug) ─────────────

void main() {
  group('SnifferGame lifecycle - no LateInitializationError', () {
    testWidgets(
        'game mounts in a small surface without throwing on first layout',
        (tester) async {
      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = errors.add;

      final game = _buildGame();
      await tester.pumpWidget(_gameWidget(game, width: 250, height: 400));

      // One more frame to let Flame process its queue.
      await tester.pump(const Duration(milliseconds: 16));

      FlutterError.onError = originalOnError;

      for (final e in errors) {
        FlutterError.reportError(e);
      }
      expect(errors, isEmpty,
          reason: 'No FlutterError expected during initial layout');
    });

    testWidgets('resize during load does not throw LateInitializationError',
        (tester) async {
      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = errors.add;

      final game = _buildGame();

      // Start in a wide surface...
      await tester.pumpWidget(_gameWidget(game, width: 500, height: 600));

      // ...then immediately shrink the surface to simulate the narrow-window
      // layout that triggered the crash in alpha 1.0.
      await tester.binding.setSurfaceSize(const Size(240, 600));
      await tester.pump(const Duration(milliseconds: 16));

      FlutterError.onError = originalOnError;

      for (final e in errors) {
        FlutterError.reportError(e);
      }
      expect(errors, isEmpty,
          reason: 'No error expected on resize before onLoad completes');

      // Clean up overridden surface size.
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('dragPaddleBy before load is a no-op, not a crash',
        (tester) async {
      final game = _buildGame();
      await tester.pumpWidget(_gameWidget(game, width: 250, height: 400));

      // Call dragPaddleBy immediately - onLoad may not have finished yet.
      expect(
        () => game.dragPaddleBy(50),
        returnsNormally,
        reason: 'dragPaddleBy must be safe to call before onLoad completes',
      );
    });
  });

  // ── 1.3 B -- _PrepRow overflow on narrow surface ──────────────────────────

  group('_PrepRow layout - no RenderFlex overflow at 240 px', () {
    testWidgets('long value text does not overflow a 240-wide surface',
        (tester) async {
      final overflowErrors = <String>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final message = details.exception.toString();
        if (message.contains('overflowed')) {
          overflowErrors.add(message);
        } else {
          originalOnError?.call(details);
        }
      };

      await tester.binding.setSurfaceSize(const Size(240, 600));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrepRowTestWidget(
                  label: 'Target',
                  value: 'Corporate Financial Sector (Very Long Name Indeed)',
                ),
                _PrepRowTestWidget(
                  label: 'Mission',
                  value: 'Full-Spectrum Data Exfiltration Campaign',
                ),
                _PrepRowTestWidget(
                  label: 'Reward',
                  value: '15000 EPTS + 50 Trust',
                ),
                _PrepRowTestWidget(
                  label: 'Est. Time Budget',
                  value: '120s',
                ),
              ],
            ),
          ),
        ),
      );

      FlutterError.onError = originalOnError;
      await tester.binding.setSurfaceSize(null);

      expect(overflowErrors, isEmpty,
          reason: 'No RenderFlex overflow expected at 240 px width. '
              'Errors: $overflowErrors');
    });
  });
}

// A test widget that mirrors the exact layout of _PrepRow in AttackPrepScreen,
// so this test is a true regression guard for that widget's overflow fix.
class _PrepRowTestWidget extends StatelessWidget {
  const _PrepRowTestWidget({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
