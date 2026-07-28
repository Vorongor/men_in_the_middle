import 'dart:async' show unawaited;
import 'dart:math' show pi, sin;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/resolution/attack_models.dart';
import '../game/resolution/resolution_engine.dart';
import '../game/sniffer/sniffer_config.dart';
import '../game/sniffer/sniffer_game.dart';
import '../services/audio_service.dart';
import '../state/attack_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/constants.dart';
import '../utils/route_args.dart';
import '../utils/routes.dart';
import '../widgets/game_scaffold.dart';

/// Screen 7.2 — hosts the hacking minigame.
///
/// Phishing missions (mission_primary_soft_type_id == 1, "Data Theft") get
/// the real "Перехоплення потоку" (Data Sniffer) Flame minigame. The other
/// three mission types don't have a dedicated minigame yet (Steps beyond the
/// alpha), so they're graded by a deterministic AUTO-RESOLVE panel instead —
/// a conscious, labeled limitation, not a bug. A kDebugMode-only row of
/// outcome buttons stays available for manual QA regardless of mission type.
class AttackScreen extends ConsumerStatefulWidget {
  const AttackScreen({super.key});

  @override
  ConsumerState<AttackScreen> createState() => _AttackScreenState();
}

class _AttackScreenState extends ConsumerState<AttackScreen> {
  SnifferGame? _snifferGame;

  @override
  void initState() {
    super.initState();
    // The keyboard loop runs for as long as the attack screen is up, whether
    // it resolves through the minigame or the auto-resolve panel.
    unawaited(AudioService.instance.startLoopSfx(AppAudio.sfxKeyboardLoop));
  }

  @override
  void dispose() {
    // Covers every exit: finish, abort, and the OS back gesture.
    unawaited(AudioService.instance.stopLoopSfx());
    super.dispose();
  }

  void _finish(BuildContext context, MinigameOutcome outcome) {
    final args = ModalRoute.of(context)!.settings.arguments as AttackPrepArgs?;
    ref.read(attackSessionProvider.notifier).resolve(outcome);
    Navigator.pushReplacementNamed(
      context,
      Routes.attackResult,
      arguments: args,
    );
  }

  Future<void> _confirmAbort(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'ABORT ATTACK?',
          style: AppTextStyles.sectionLabel(color: AppColors.text).copyWith(fontSize: 14, letterSpacing: 1),
        ),
        content: Text(
          'Bailing out now counts as a failed attack — you keep no reward '
          'and still risk being traced.',
          style: AppTextStyles.body(color: AppColors.textHigh),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('KEEP GOING', style: AppTextStyles.button(color: AppColors.textHigh)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ABORT', style: AppTextStyles.button(color: AppColors.alert)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      _snifferGame?.abort();
      _finish(context, const MinigameOutcome(success: false, timeRatio: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(attackSessionProvider).setup;

    if (setup == null) {
      return GameScaffold(
        screenNum: '7.2',
        screenName: 'ATTACK',
        showSettings: false,
        body: Center(
          child: Text(
            'No attack in progress. Go back and prepare one first.',
            style: AppTextStyles.body(color: AppColors.textMuted),
          ),
        ),
      );
    }

    // Phishing missions (Data Theft) get the real minigame; everything else
    // auto-resolves for this alpha (see docs/planning/step_08, criteria).
    final isPhishing = setup.contract.missionPrimarySoftTypeId == 1;

    // Hardware/OS back gesture mid-attack goes through the same confirmation
    // as the ABORT button — leaving silently would just orphan the session.
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmAbort(context);
      },
      child: GameScaffold(
        screenNum: '7.2',
        screenName: 'ATTACK',
        showSettings: false,
        body: Column(
          children: [
            _AttackHeader(setup: setup),
            const Divider(),
            Expanded(
              child: isPhishing
                  ? _SnifferMinigame(
                      setup: setup,
                      onGameReady: (g) => _snifferGame = g,
                      onComplete: (o) => _finish(context, o),
                    )
                  : _AutoResolvePanel(
                      setup: setup,
                      onResolve: (o) => _finish(context, o),
                    ),
            ),
            if (kDebugMode) _DebugOutcomeBar(onPick: (o) => _finish(context, o)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmAbort(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'ABORT',
                    style: AppTextStyles.button(color: AppColors.textMuted).copyWith(fontSize: 11, letterSpacing: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttackHeader extends StatelessWidget {
  const _AttackHeader({required this.setup});
  final AttackSetup setup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          const Icon(Icons.radar, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  setup.contract.targetName.toUpperCase(),
                  style: AppTextStyles.dataMono(color: AppColors.text),
                ),
                Text(
                  setup.contract.missionName.toUpperCase(),
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Embeds [SnifferGame] and forwards drag/lifecycle events to it. Screen
/// shake on a red hit is done at the Flutter layer (a decaying
/// [Transform.translate] wobble) rather than via Flame's camera, keeping the
/// game itself free of viewfinder-juggling for a one-off cosmetic effect.
class _SnifferMinigame extends StatefulWidget {
  const _SnifferMinigame({
    required this.setup,
    required this.onGameReady,
    required this.onComplete,
  });

  final AttackSetup setup;
  final ValueChanged<SnifferGame> onGameReady;
  final ValueChanged<MinigameOutcome> onComplete;

  @override
  State<_SnifferMinigame> createState() => _SnifferMinigameState();
}

class _SnifferMinigameState extends State<_SnifferMinigame>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final SnifferGame _game;
  late final AnimationController _shakeController;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _game = SnifferGame(
      config: SnifferConfig.fromSetup(widget.setup),
      onComplete: (outcome) {
        if (_completed) return;
        _completed = true;
        widget.onComplete(outcome);
      },
      onRedHit: () => _shakeController
        ..reset()
        ..forward(),
    );
    widget.onGameReady(_game);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final backgrounded = state != AppLifecycleState.resumed;
    if (backgrounded) {
      _game.pauseEngine();
    } else {
      _game.resumeEngine();
    }
    // Keep the typing loop in lockstep with the engine, so a backgrounded app
    // isn't still clattering away.
    unawaited(AudioService.instance.setLoopPaused(backgrounded));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => _game.dragPaddleBy(details.delta.dx),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final t = _shakeController.value;
          final offset = sin(t * pi * 6) * (1 - t) * 6;
          return Transform.translate(offset: Offset(offset, 0), child: child);
        },
        child: GameWidget(game: _game),
      ),
    );
  }
}

/// Non-Phishing missions don't have a real minigame yet (Steps beyond the
/// alpha bring the other three). This panel grades the attack deterministically
/// from the player's effective attack vs. the target's defense, labeled
/// clearly so it doesn't read as a missing feature.
class _AutoResolvePanel extends StatelessWidget {
  const _AutoResolvePanel({required this.setup, required this.onResolve});

  final AttackSetup setup;
  final ValueChanged<MinigameOutcome> onResolve;

  MinigameOutcome _computeOutcome() {
    final defense = setup.contract.defense;
    final ratio = defense <= 0
        ? 1.0
        : ResolutionEngine.effectiveAttack(setup) / defense;
    return MinigameOutcome(success: ratio >= 0.5, timeRatio: ratio.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, color: AppColors.iconLow, size: 40),
            const SizedBox(height: 16),
            Text(
              '[ AUTO-RESOLVE ]',
              style: AppTextStyles.sectionLabel(color: AppColors.textMuted).copyWith(fontSize: 13, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
            Text(
              '${setup.contract.missionName} has no dedicated minigame in this '
              'alpha build — it resolves automatically from your equipped gear.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: AppColors.textMuted).copyWith(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onResolve(_computeOutcome()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.borderSuccess),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'AUTO-RESOLVE',
                  style: AppTextStyles.button(color: AppColors.primary).copyWith(fontSize: 12, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Manual outcome override for QA — only ever shown in debug builds.
class _DebugOutcomeBar extends StatelessWidget {
  const _DebugOutcomeBar({required this.onPick});
  final ValueChanged<MinigameOutcome> onPick;

  Widget _btn(String label, Color color, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      padding: const EdgeInsets.symmetric(vertical: 8),
    ),
    child: Text(label, style: const TextStyle(fontSize: 10)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: AppColors.surfaceError,
      child: Column(
        children: [
          Text(
            'DEBUG OVERRIDE (kDebugMode)',
            style: AppTextStyles.caption(color: AppColors.iconLow).copyWith(fontSize: 9, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _btn(
                  'PERFECT',
                  AppColors.primary,
                  () => onPick(const MinigameOutcome(success: true, timeRatio: 0.85)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _btn(
                  'SLOW',
                  AppColors.warning,
                  () => onPick(const MinigameOutcome(success: true, timeRatio: 0.2)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _btn(
                  'FAIL',
                  AppColors.alert,
                  () => onPick(const MinigameOutcome(success: false, timeRatio: 0.0)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
