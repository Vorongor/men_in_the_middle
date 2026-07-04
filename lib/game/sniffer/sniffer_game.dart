import 'dart:async' show unawaited;
import 'dart:ui' show Color, Paint;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart' show Colors, KeyEventResult, TextStyle;
import 'package:flutter/services.dart' show KeyEvent, LogicalKeyboardKey;

import '../../services/audio_service.dart';
import '../../utils/constants.dart';
import '../resolution/attack_models.dart';
import 'packet.dart';
import 'packet_spawner.dart';
import 'sniffer_config.dart';
import 'sniffer_outcome.dart';
import 'sniffer_paddle.dart';

/// "Перехоплення потоку" (Data Sniffer) — the alpha's one real minigame.
///
/// Catch [SnifferConfig.targetCatches] green packets before the timer runs
/// out or too many red packets hit the paddle. Drag anywhere (or use the
/// arrow keys on desktop) to move the paddle; [onComplete] fires exactly
/// once with the graded [MinigameOutcome].
class SnifferGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  SnifferGame({
    required this.config,
    required this.onComplete,
    this.onRedHit,
  });

  final SnifferConfig config;
  final void Function(MinigameOutcome outcome) onComplete;
  final void Function()? onRedHit;

  static const double _keyboardSpeed = 260;
  static const double _basePaddleWidth = 70;

  late final SnifferPaddle paddle;
  late final PacketSpawner spawner;
  late final TextComponent _timerText;
  late final TextComponent _progressText;
  late final TextComponent _hitsText;

  int caughtGreen = 0;
  int redHits = 0;
  double timeRemaining = 0;
  bool isSpawning = true;

  bool _finished = false;
  final Set<LogicalKeyboardKey> _keysDown = {};

  @override
  Future<void> onLoad() async {
    // Restore the classic "world origin = top-left, 1 unit = 1 px" mapping;
    // the default CameraComponent centers the world on the viewport, which
    // would otherwise put (0,0) in the middle of the screen.
    camera.viewfinder.anchor = Anchor.topLeft;

    timeRemaining = config.timeBudgetSeconds.toDouble();

    paddle = SnifferPaddle(
      width: _basePaddleWidth * config.paddleWidthFactor,
      position: Vector2(size.x / 2, size.y - 40),
    );
    paddle.setBounds(size.x);
    await world.add(paddle);

    spawner = PacketSpawner(config: config);
    await world.add(spawner);

    final hudStyle = TextPaint(
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontFamily: 'monospace',
      ),
    );
    await camera.viewport.addAll([
      _timerText = TextComponent(position: Vector2(12, 8), textRenderer: hudStyle),
      _progressText = TextComponent(position: Vector2(12, 26), textRenderer: hudStyle),
      _hitsText = TextComponent(position: Vector2(12, 44), textRenderer: hudStyle),
    ]);
    _refreshHud();
  }

  // onGameResize is intentionally not overridden here.
  // SnifferPaddle.onGameResize handles its own bounds update after mount,
  // which structurally eliminates the LateInitializationError race.

  void _refreshHud() {
    _timerText.text = 'TIME  ${timeRemaining.ceil()}s';
    _progressText.text = 'CAUGHT  $caughtGreen / ${config.targetCatches}';
    _hitsText.text = 'HITS  $redHits / ${config.allowedRedHits}';
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished) return;

    if (_keysDown.contains(LogicalKeyboardKey.arrowLeft)) {
      paddle.moveBy(-_keyboardSpeed * dt);
    }
    if (_keysDown.contains(LogicalKeyboardKey.arrowRight)) {
      paddle.moveBy(_keyboardSpeed * dt);
    }

    timeRemaining -= dt;
    if (timeRemaining <= 0) {
      timeRemaining = 0;
      _refreshHud();
      _finish();
      return;
    }
    _refreshHud();
  }

  /// Called by [Packet] on a successful paddle collision.
  void registerCatch(PacketKind kind, {required Vector2 worldPosition}) {
    if (_finished) return;
    unawaited(Future.sync(() => world.add(_CatchFlash(position: worldPosition))));
    if (kind == PacketKind.green) {
      caughtGreen++;
      unawaited(AudioService.instance.playSfx(AppAudio.sfxCatch));
      if (caughtGreen >= config.targetCatches) {
        _finish();
        return;
      }
    } else {
      redHits++;
      unawaited(AudioService.instance.playSfx(AppAudio.sfxHit));
      onRedHit?.call();
      if (redHits > config.allowedRedHits) {
        _finish();
        return;
      }
    }
    _refreshHud();
  }

  /// Player-initiated bail-out: always grades as a clean failure, regardless
  /// of how close they were to winning.
  void abort() {
    if (_finished) return;
    _finished = true;
    isSpawning = false;
    unawaited(AudioService.instance.playSfx(AppAudio.sfxLose));
    onComplete(const MinigameOutcome(success: false, timeRatio: 0));
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    isSpawning = false;
    final outcome = SnifferOutcomeCalculator.compute(
      config: config,
      caughtGreen: caughtGreen,
      redHits: redHits,
      timeRemainingSeconds: timeRemaining,
    );
    unawaited(
      AudioService.instance.playSfx(
        outcome.success ? AppAudio.sfxWin : AppAudio.sfxLose,
      ),
    );
    onComplete(outcome);
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  /// Forwarded from a [GestureDetector] wrapping the [GameWidget] — Flame's
  /// own drag-callback plumbing adds a dispatcher indirection that isn't
  /// worth it for "drag anywhere moves the paddle".
  ///
  /// No-op if [onLoad] hasn't finished yet (paddle is not initialised).
  void dragPaddleBy(double dx) {
    if (!isLoaded) return;
    paddle.moveBy(dx);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keysDown
      ..clear()
      ..addAll(keysPressed);
    return KeyEventResult.handled;
  }
}

/// A brief expanding, fading dot left behind at a successful catch.
class _CatchFlash extends CircleComponent {
  _CatchFlash({required Vector2 position})
    : super(
        radius: 6,
        position: position,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF39D353).withValues(alpha: 0.7),
      );

  static const _duration = 0.25;
  double _life = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    final t = (_life / _duration).clamp(0.0, 1.0);
    radius = 6 + 18 * t;
    paint.color = paint.color.withValues(alpha: 0.7 * (1 - t));
    if (_life >= _duration) removeFromParent();
  }
}
