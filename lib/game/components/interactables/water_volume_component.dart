import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WaterVolumeComponent extends PositionComponent {
  WaterVolumeComponent({required super.position, required super.size})
    : super(anchor: Anchor.topLeft);

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF1F6FB2).withValues(alpha: 0.62),
    );
    final ripple = Paint()
      ..color = const Color(0xFF7FD1E8).withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var x = 8.0; x < size.x; x += 28) {
      canvas.drawArc(
        Rect.fromLTWH(x, 6, 16, 7),
        0,
        3.14159,
        false,
        ripple,
      );
    }
  }
}
