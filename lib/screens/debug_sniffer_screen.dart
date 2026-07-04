import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/resolution/attack_models.dart';
import '../game/sniffer/sniffer_config.dart';
import '../game/sniffer/sniffer_game.dart';

/// `/debug/sniffer` — kDebugMode-only tuning tool.
///
/// Lets a developer play the Data Sniffer minigame with a hand-picked
/// [SnifferConfig], bypassing the full attack flow (no profile, no contract,
/// no persistence) so difficulty can be iterated on quickly. Per
/// docs/planning/step_08 §8.4.
class DebugSnifferScreen extends StatefulWidget {
  const DebugSnifferScreen({super.key});

  @override
  State<DebugSnifferScreen> createState() => _DebugSnifferScreenState();
}

class _DebugSnifferScreenState extends State<DebugSnifferScreen> {
  double _timeBudget = 30;
  double _targetCatches = 10;
  double _paddleWidthFactor = 1.2;
  double _allowedRedHits = 1;
  double _fallSpeed = 160;
  double _redRatio = 0.25;
  double _chameleonChance = 0.0;
  double _spawnInterval = 0.6;

  void _launch() {
    final config = SnifferConfig(
      timeBudgetSeconds: _timeBudget.round(),
      targetCatches: _targetCatches.round(),
      paddleWidthFactor: _paddleWidthFactor,
      allowedRedHits: _allowedRedHits.round(),
      fallSpeed: _fallSpeed,
      redRatio: _redRatio,
      chameleonChance: _chameleonChance,
      spawnIntervalSeconds: _spawnInterval,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DebugSnifferPlayScreen(config: config),
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.greenAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('DEBUG: SNIFFER TUNING', style: TextStyle(fontSize: 13)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _slider('Time Budget (s)', _timeBudget, 10, 60, (v) => setState(() => _timeBudget = v)),
          _slider(
            'Target Catches',
            _targetCatches,
            5,
            25,
            (v) => setState(() => _targetCatches = v),
          ),
          _slider(
            'Paddle Width Factor',
            _paddleWidthFactor,
            0.5,
            2.5,
            (v) => setState(() => _paddleWidthFactor = v),
          ),
          _slider(
            'Allowed Red Hits',
            _allowedRedHits,
            0,
            5,
            (v) => setState(() => _allowedRedHits = v),
          ),
          _slider(
            'Fall Speed (px/s)',
            _fallSpeed,
            60,
            420,
            (v) => setState(() => _fallSpeed = v),
          ),
          _slider('Red Ratio', _redRatio, 0.1, 0.5, (v) => setState(() => _redRatio = v)),
          _slider(
            'Chameleon Chance',
            _chameleonChance,
            0.0,
            1.0,
            (v) => setState(() => _chameleonChance = v),
          ),
          _slider(
            'Spawn Interval (s)',
            _spawnInterval,
            0.2,
            1.2,
            (v) => setState(() => _spawnInterval = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _launch, child: const Text('START')),
        ],
      ),
    );
  }
}

class _DebugSnifferPlayScreen extends StatefulWidget {
  const _DebugSnifferPlayScreen({required this.config});
  final SnifferConfig config;

  @override
  State<_DebugSnifferPlayScreen> createState() => _DebugSnifferPlayScreenState();
}

class _DebugSnifferPlayScreenState extends State<_DebugSnifferPlayScreen> {
  late final SnifferGame _game;

  @override
  void initState() {
    super.initState();
    _game = SnifferGame(config: widget.config, onComplete: _onComplete);
  }

  void _onComplete(MinigameOutcome outcome) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        title: Text(
          outcome.success ? 'SUCCESS' : 'FAIL',
          style: TextStyle(color: outcome.success ? Colors.greenAccent : Colors.redAccent),
        ),
        content: Text(
          'timeRatio: ${outcome.timeRatio.toStringAsFixed(2)}\nperfect: ${outcome.perfect}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('BACK TO TUNING'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragUpdate: (d) => _game.dragPaddleBy(d.delta.dx),
          child: GameWidget(game: _game),
        ),
      ),
    );
  }
}
