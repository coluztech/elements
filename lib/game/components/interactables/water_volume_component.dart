import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WaterVolumeComponent extends PositionComponent {
  WaterVolumeComponent({required super.position, required super.size})
    : super(anchor: Anchor.topLeft);

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final surface = Path()..moveTo(0, rect.height);
    const step = 12.0;
    for (var x = 0.0; x <= rect.width; x += step) {
      final wave =
          math.sin(x * 0.045 + _time * 2.1) * 2.2 +
          math.sin(x * 0.021 - _time * 1.4) * 1.2;
      final y = 5 + wave;
      if (x == 0) {
        surface.lineTo(x, y);
      } else {
        final previousX = x - step;
        final previousWave =
            math.sin(previousX * 0.045 + _time * 2.1) * 2.2 +
            math.sin(previousX * 0.021 - _time * 1.4) * 1.2;
        final previousY = 5 + previousWave;
        surface.cubicTo(
          previousX + step * 0.36,
          previousY,
          previousX + step * 0.64,
          y,
          x,
          y,
        );
      }
    }
    surface
      ..lineTo(rect.width, rect.height)
      ..close();

    canvas.save();
    canvas.clipPath(surface);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB86AC6E8), Color(0xC42C91C7), Color(0xD0185A91)],
        ).createShader(rect),
    );

    final caustic = Paint()
      ..color = const Color(0xFFBAF2FF).withValues(alpha: 0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var row = 0; row < 3; row++) {
      final y = rect.height * (0.34 + row * 0.23);
      final path = Path();
      for (var x = 0.0; x <= rect.width; x += step) {
        final offset = math.sin(x * 0.032 + _time * 1.3 + row) * 3;
        if (x == 0) {
          path.moveTo(x, y + offset);
        } else {
          path.lineTo(x, y + offset);
        }
      }
      canvas.drawPath(path, caustic);
    }

    final glint = Paint()
      ..color = const Color(0xFFD6FAFF).withValues(alpha: 0.48);
    for (var x = 14.0; x < rect.width; x += 54) {
      final y =
          5 +
          math.sin(x * 0.045 + _time * 2.1) * 2.2 +
          math.sin(x * 0.021 - _time * 1.4) * 1.2;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y - 1), width: 12, height: 2),
        glint,
      );
    }
    canvas.restore();

    final edge = Path();
    for (var x = 0.0; x <= rect.width; x += step) {
      final y =
          5 +
          math.sin(x * 0.045 + _time * 2.1) * 2.2 +
          math.sin(x * 0.021 - _time * 1.4) * 1.2;
      if (x == 0) {
        edge.moveTo(x, y);
      } else {
        edge.lineTo(x, y);
      }
    }
    canvas.drawPath(
      edge,
      Paint()
        ..color = const Color(0xFFB7F1FF).withValues(alpha: 0.82)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }
}
