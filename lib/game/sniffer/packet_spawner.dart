import 'dart:math';

import 'package:flame/components.dart';

import 'packet.dart';
import 'sniffer_config.dart';
import 'sniffer_game.dart';

/// Periodically drops a new [Packet] into the world, mixing in reds
/// (and, at higher difficulty, chameleons) per [SnifferConfig].
class PacketSpawner extends Component with HasGameReference<SnifferGame> {
  PacketSpawner({required this.config, Random? random}) : _rng = random ?? Random();

  final SnifferConfig config;
  final Random _rng;

  double _sinceLastSpawn = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isSpawning) return;
    _sinceLastSpawn += dt;
    if (_sinceLastSpawn >= config.spawnIntervalSeconds) {
      _sinceLastSpawn = 0;
      _spawnOne();
    }
  }

  void _spawnOne() {
    final isRed = _rng.nextDouble() < config.redRatio;
    final chameleon = isRed && _rng.nextDouble() < config.chameleonChance;
    final margin = 20.0;
    final width = game.size.x;
    final x = width <= margin * 2
        ? width / 2
        : margin + _rng.nextDouble() * (width - margin * 2);

    game.world.add(
      Packet(
        kind: isRed ? PacketKind.red : PacketKind.green,
        chameleon: chameleon,
        fallSpeed: config.fallSpeed,
        position: Vector2(x, -20),
      ),
    );
  }
}
