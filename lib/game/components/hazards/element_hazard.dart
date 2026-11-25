import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/systems/hazard_response_resolver.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

abstract class ElementHazard extends PositionComponent with CollisionCallbacks {
  ElementHazard({
    required this.hazardType,
    required Vector2 position,
    required Vector2 size,
    required this.fill,
    this.isLive = true,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  final HazardType hazardType;
  final Color fill;
  bool isLive;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!isLive ||
        other is! PlayerComponent ||
        other.lifeState != PlayerLifeState.alive) {
      return;
    }

    final outcome = HazardResponseResolver.resolve(
      hazardType,
      other.element,
      isLive: isLive,
    );
    if (outcome == HazardOutcome.extinguishesHazard) isLive = false;
    other.handleHazardOutcome(outcome);
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = isLive ? fill : fill.withValues(alpha: 0.18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = Colors.white.withValues(alpha: isLive ? 0.75 : 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
