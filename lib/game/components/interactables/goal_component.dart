import 'dart:async';

import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/components/world_art_cache.dart';
import 'package:elements/services/audio_service.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GoalComponent extends PositionComponent with CollisionCallbacks {
  GoalComponent({
    required Vector2 position,
    required Vector2 size,
    required this.onReached,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  final VoidCallback onReached;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(collisionType: CollisionType.passive));
    unawaited(WorldArtCache.preload('fx/goal_portal.png').catchError((_) {}));
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent && other.lifeState == PlayerLifeState.alive) {
      other.lifeState = PlayerLifeState.levelComplete;
      AudioService.instance.emit(GameAudioEvent.levelCompleted);
      onReached();
    }
  }

  @override
  void render(Canvas canvas) {
    final image = WorldArtCache.image('fx/goal_portal.png');
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        size.toRect(),
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
    final rect = size.toRect();
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF3D7A3D),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
