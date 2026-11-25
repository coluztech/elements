import 'dart:async';

import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/components/world_art_cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CheckpointComponent extends PositionComponent with CollisionCallbacks {
  CheckpointComponent({
    required Vector2 position,
    required Vector2 respawnPosition,
  }) : respawnPosition = respawnPosition.clone(),
       super(position: position, size: Vector2(32, 72), anchor: Anchor.topLeft);

  final Vector2 respawnPosition;
  bool isActivated = false;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(collisionType: CollisionType.passive));
    unawaited(
      WorldArtCache.preload('fx/checkpoint_beacon.png').catchError((_) {}),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      other.activateCheckpoint(respawnPosition);
      isActivated = true;
    }
  }

  @override
  void render(Canvas canvas) {
    final image = WorldArtCache.image('fx/checkpoint_beacon.png');
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(-8, -4, size.x + 16, size.y + 8),
        Paint()..filterQuality = FilterQuality.medium,
      );
      if (isActivated) {
        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          20,
          Paint()..color = const Color(0xFF8FD17A).withValues(alpha: 0.18),
        );
      }
      return;
    }
    final pole = Rect.fromLTWH(13, 0, 6, size.y);
    canvas.drawRect(pole, Paint()..color = const Color(0xFF5B3E96));
    final flag = Path()
      ..moveTo(19, 4)
      ..lineTo(32, 10)
      ..lineTo(19, 18)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFF8FD17A));
  }
}
