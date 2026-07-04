import 'dart:ui' show Color, Paint;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, FontWeight, TextStyle;

import 'sniffer_game.dart';
import 'sniffer_paddle.dart';

enum PacketKind { green, red }

/// A falling "data packet". Green ones should be caught, red ones avoided —
/// per docs/game_concept.md's "Перехоплення потоку" (Data Sniffer) minigame.
///
/// A chameleon packet is secretly [PacketKind.red] but renders green until
/// [_revealAfter] seconds have passed, matching the concept's "Пакет-хамелеон"
/// escalation (disguised, reveals itself just before it would be caught).
class Packet extends RectangleComponent
    with CollisionCallbacks, HasGameReference<SnifferGame> {
  Packet({
    required this.kind,
    required this.fallSpeed,
    required Vector2 position,
    this.chameleon = false,
  }) : super(
         position: position,
         size: Vector2.all(28),
         anchor: Anchor.center,
         paint: Paint()..color = chameleon ? _green : _colorFor(kind),
       );

  static const _revealAfter = 0.5;
  static const _green = Color(0xFF39D353);
  static const _red = Color(0xFFE5484D);

  static Color _colorFor(PacketKind kind) =>
      kind == PacketKind.green ? _green : _red;

  final PacketKind kind;
  final bool chameleon;
  final double fallSpeed;

  bool _revealed = false;
  double _age = 0;
  bool _consumed = false;

  late final TextComponent _label;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _revealed = !chameleon;
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    add(
      _label = TextComponent(
        text: _revealed && kind == PacketKind.red ? '0' : '1',
        position: size / 2,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;

    if (chameleon && !_revealed) {
      _age += dt;
      if (_age >= _revealAfter) {
        _revealed = true;
        paint.color = _red;
        _label.text = '0';
      }
    }

    // Missing a packet (of either color) is free — only a paddle hit on a
    // red one is penalized — so falling off the bottom just cleans it up.
    if (position.y - size.y / 2 > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_consumed || other is! SnifferPaddle) return;
    _consumed = true;
    game.registerCatch(kind, worldPosition: position.clone());
    removeFromParent();
  }
}
