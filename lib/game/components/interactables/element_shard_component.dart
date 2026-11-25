import 'package:elements/game/components/player/player_component.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ElementShardComponent extends PositionComponent with CollisionCallbacks {
  ElementShardComponent({required Vector2 position, required this.onCollected})
    : super(position: position, size: Vector2.all(20), anchor: Anchor.center);

  final VoidCallback onCollected;
  bool _collected = false;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_collected ||
        other is! PlayerComponent ||
        other.lifeState != PlayerLifeState.alive) {
      return;
    }
    _collected = true;
    onCollected();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final points = <Offset>[
      center.translate(0, -9),
      center.translate(8, 0),
      center.translate(0, 9),
      center.translate(-8, 0),
    ];
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, Paint()..color = const Color(0xFF8FD17A));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
