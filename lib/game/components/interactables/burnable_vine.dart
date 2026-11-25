import 'dart:ui';

import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/components/terrain/solid_block.dart';
import 'package:elements/models/element_type.dart';
import 'package:flutter/material.dart';

class BurnableVine extends SolidBlock {
  BurnableVine({
    required super.position,
    required super.size,
    required this.player,
  }) : super(fill: const Color(0xFF587342));

  final PlayerComponent player;

  @override
  void update(double dt) {
    super.update(dt);
    if (isSolid &&
        player.lifeState == PlayerLifeState.alive &&
        player.element == ElementType.fire &&
        toAbsoluteRect().inflate(4).overlaps(player.body.aabb)) {
      player.visual.playAbility(ElementType.fire);
      isSolid = false;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isSolid) return;
    super.render(canvas);
    final vinePaint = Paint()
      ..color = const Color(0xFF8FD17A)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    for (var x = 8.0; x < size.x; x += 16) {
      final path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(x - 7, size.y / 2, x, size.y);
      canvas.drawPath(path, vinePaint);
    }
    if (player.element == ElementType.fire) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFFFF8A50).withValues(alpha: 0.2),
      );
    }
  }
}
