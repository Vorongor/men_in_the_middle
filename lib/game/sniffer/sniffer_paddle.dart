import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// The player-controlled "sniffer" at the bottom of the screen. Wider
/// paddles (driven by [SnifferConfig.paddleWidthFactor], which scales with
/// software attack) are easier to land catches with.
class SnifferPaddle extends RectangleComponent with CollisionCallbacks {
  SnifferPaddle({required double width, required Vector2 position})
    : _minX = 0,
      _maxX = 0,
      super(
        position: position,
        size: Vector2(width, 18),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF39D353),
      );

  double _minX;
  double _maxX;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  /// Called whenever the playable area width is known/changes so drags and
  /// keyboard movement can't push the paddle off-screen.
  void setBounds(double screenWidth) {
    _minX = size.x / 2;
    _maxX = screenWidth - size.x / 2;
  }

  void moveBy(double dx) => moveTo(position.x + dx);

  void moveTo(double x) {
    if (_maxX <= _minX) {
      position.x = x;
      return;
    }
    position.x = x.clamp(_minX, _maxX);
  }
}
