import 'dart:async';
import 'dart:math' as math;

import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/components/world_art_cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CollectibleStarComponent extends PositionComponent
    with CollisionCallbacks {
  CollectibleStarComponent({
    required Vector2 position,
    required this.onCollected,
  }) : super(position: position, size: Vector2.all(30), anchor: Anchor.center);

  final VoidCallback onCollected;
  bool _collected = false;
  double _age = 0;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(collisionType: CollisionType.passive));
    unawaited(
      WorldArtCache.preload('fx/collectible_star.png').catchError((_) {}),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
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
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 + math.sin(_age * 3) * 2);
    canvas.rotate(math.sin(_age * 2) * 0.08);
    final image = WorldArtCache.image('fx/collectible_star.png');
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final radius = i.isEven ? 14.0 : 6.5;
        final angle = -math.pi / 2 + i * math.pi / 5;
        final point = Offset(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFFFD166));
    }
    canvas.restore();
  }
}
