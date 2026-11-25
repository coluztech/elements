import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Deep, layered night-sky backdrop with restrained elemental color accents.
class LevelBackdrop extends PositionComponent {
  LevelBackdrop({required Vector2 size})
    : super(size: size, anchor: Anchor.topLeft, priority: -100);

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final bounds = size.toRect();
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111322), Color(0xFF28223D), Color(0xFF473754)],
          stops: [0, 0.66, 1],
        ).createShader(bounds),
    );

    canvas.drawCircle(
      Offset(size.x * 0.78, size.y * 0.24),
      size.x * 0.2,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF8A6BBA).withValues(alpha: 0.17),
                const Color(0xFF8A6BBA).withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.x * 0.78, size.y * 0.24),
                radius: size.x * 0.2,
              ),
            ),
    );

    final farLayer = Path()
      ..moveTo(0, size.y * 0.62)
      ..cubicTo(
        size.x * 0.18,
        size.y * 0.42,
        size.x * 0.3,
        size.y * 0.67,
        size.x * 0.48,
        size.y * 0.53,
      )
      ..cubicTo(
        size.x * 0.69,
        size.y * 0.38,
        size.x * 0.82,
        size.y * 0.68,
        size.x,
        size.y * 0.48,
      )
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(
      farLayer,
      Paint()..color = const Color(0xFF302B46).withValues(alpha: 0.78),
    );

    final nearLayer = Path()
      ..moveTo(0, size.y * 0.72)
      ..cubicTo(
        size.x * 0.24,
        size.y * 0.58,
        size.x * 0.35,
        size.y * 0.76,
        size.x * 0.57,
        size.y * 0.64,
      )
      ..cubicTo(
        size.x * 0.78,
        size.y * 0.52,
        size.x * 0.9,
        size.y * 0.72,
        size.x,
        size.y * 0.61,
      )
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(
      nearLayer,
      Paint()..color = const Color(0xFF3B334D).withValues(alpha: 0.86),
    );

    final horizon = Paint()
      ..color = const Color(0xFFB39AD8).withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.y * 0.78),
      Offset(size.x, size.y * 0.78),
      horizon,
    );

    for (var i = 0; i < 38; i++) {
      final x = ((i * 197 + 83) % 997) / 997 * size.x;
      final y = ((i * 131 + 29) % 479) / 479 * size.y * 0.62;
      final pulse = 0.18 + 0.32 * (0.5 + 0.5 * math.sin(_time * 1.5 + i));
      canvas.drawCircle(
        Offset(x, y),
        i % 7 == 0 ? 1.7 : 1,
        Paint()..color = const Color(0xFFE6D9FF).withValues(alpha: pulse),
      );
    }

    final arch = Path()
      ..moveTo(size.x * 0.1, size.y * 0.78)
      ..lineTo(size.x * 0.1, size.y * 0.57)
      ..quadraticBezierTo(
        size.x * 0.1,
        size.y * 0.34,
        size.x * 0.28,
        size.y * 0.34,
      )
      ..quadraticBezierTo(
        size.x * 0.45,
        size.y * 0.34,
        size.x * 0.45,
        size.y * 0.57,
      )
      ..lineTo(size.x * 0.45, size.y * 0.78);
    canvas.drawPath(
      arch,
      Paint()
        ..color = const Color(0xFFC9A96E).withValues(alpha: 0.17)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
