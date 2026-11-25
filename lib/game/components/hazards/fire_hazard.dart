import 'dart:math' as math;

import 'package:elements/game/components/hazards/element_hazard.dart';
import 'package:elements/game/systems/hazard_response_resolver.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FireHazard extends ElementHazard {
  FireHazard({required super.position, required super.size})
    : super(hazardType: HazardType.fire, fill: const Color(0xFFC0392B));

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!isLive) {
      super.render(canvas);
      return;
    }

    final rect = size.toRect();
    final base = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7B3025), Color(0xFF3D252B)],
        ).createShader(rect),
    );
    for (var x = 7.0; x < size.x; x += 13) {
      final flicker = (math.sin(_time * 9 + x * 0.17) + 1) * 0.5;
      final height = 7 + flicker * math.min(12, size.y * 0.6);
      final flame = Path()
        ..moveTo(x - 5, 3)
        ..quadraticBezierTo(x - 7, -height * 0.45, x - 1, -height)
        ..quadraticBezierTo(x + 1, -height * 0.55, x + 5, 3)
        ..close();
      canvas.drawPath(
        flame,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFF5B32),
            const Color(0xFFFFD166),
            flicker * 0.7,
          )!,
      );
    }
    final emberLine = Path()
      ..moveTo(3, size.y * 0.56)
      ..cubicTo(
        size.x * 0.24,
        size.y * 0.3,
        size.x * 0.42,
        size.y * 0.85,
        size.x * 0.63,
        size.y * 0.52,
      )
      ..cubicTo(
        size.x * 0.79,
        size.y * 0.28,
        size.x * 0.88,
        size.y * 0.74,
        size.x - 3,
        size.y * 0.42,
      );
    canvas.drawPath(
      emberLine,
      Paint()
        ..color = const Color(0xFFFFC15E).withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      base,
      Paint()
        ..color = const Color(0xFFFFA047).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
