import 'dart:math' as math;

import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/components/terrain/solid_block.dart';
import 'package:elements/models/element_type.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TemporaryWoodStructure extends SolidBlock {
  TemporaryWoodStructure({
    required super.position,
    required super.size,
    required this.durationSeconds,
  }) : assert(durationSeconds >= 2),
       super(fill: const Color(0xFF8B542E));

  final double durationSeconds;
  double _remaining = 0;
  double _age = 0;

  void beginDecay() => _remaining = durationSeconds;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_remaining <= 0) return;
    _remaining -= dt;
    if (_remaining <= 0) {
      isSolid = false;
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent && other.element == ElementType.fire) {
      isSolid = false;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isSolid) return;
    final growth = (_age / 0.24).clamp(0.0, 1.0).toDouble();
    if (size.y > size.x) {
      _renderVine(canvas, growth);
      return;
    }
    final rect = size.toRect();
    final visibleWidth = rect.width * growth;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, visibleWidth, rect.height));
    final board = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(
      board.shift(const Offset(0, 2)),
      Paint()..color = const Color(0xFF402B25).withValues(alpha: 0.38),
    );
    canvas.drawRRect(
      board,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC98A4B), Color(0xFF9B6035), Color(0xFF704329)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, math.min(4, size.y)),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE7B878),
    );
    final seam = Paint()
      ..color = const Color(0xFF583722).withValues(alpha: 0.72)
      ..strokeWidth = 1.5;
    for (var x = 32.0; x < size.x; x += 48) {
      canvas.drawLine(Offset(x, 4), Offset(x, size.y - 2), seam);
    }
    final grain = Paint()
      ..color = const Color(0xFFE0A768).withValues(alpha: 0.52)
      ..strokeWidth = 1.2;
    for (var x = 12.0; x < size.x; x += 64) {
      canvas.drawLine(
        Offset(x, size.y * 0.48),
        Offset(math.min(x + 20, size.x - 3), size.y * 0.48),
        grain,
      );
    }
    canvas.drawLine(
      Offset(1, size.y - 1),
      Offset(size.x - 1, size.y - 1),
      Paint()
        ..color = const Color(0xFF4B3024)
        ..strokeWidth = 2,
    );
    // Small leaves at the growing edge make the summoned bridge read as wood.
    final sproutX = (visibleWidth - 4).clamp(2.0, size.x - 2).toDouble();
    final leafPaint = Paint()..color = const Color(0xFF9DDB78);
    for (var side = -1; side <= 1; side += 2) {
      final leaf = Path()
        ..moveTo(sproutX, 2)
        ..quadraticBezierTo(sproutX + side * 8, -7, sproutX + side * 11, 1)
        ..quadraticBezierTo(sproutX + side * 5, 5, sproutX, 2);
      canvas.drawPath(leaf, leafPaint);
    }
    canvas.restore();
    if (_remaining > 0 && _remaining <= 2) {
      final alpha = 0.35 + ((_remaining * 3).floor().isEven ? 0.4 : 0.0);
      canvas.drawRect(
        size.toRect(),
        Paint()..color = const Color(0xFFB7F08D).withValues(alpha: alpha),
      );
    }
  }

  void _renderVine(Canvas canvas, double growth) {
    final grownHeight = size.y * growth;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, size.y - grownHeight, size.x, grownHeight),
    );
    final stem = Path()
      ..moveTo(size.x / 2, size.y)
      ..cubicTo(
        size.x * 0.15,
        size.y * 0.72,
        size.x * 0.86,
        size.y * 0.48,
        size.x / 2,
        size.y * 0.24,
      )
      ..cubicTo(
        size.x * 0.22,
        size.y * 0.12,
        size.x * 0.7,
        size.y * 0.06,
        size.x / 2,
        0,
      );
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF345B38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(5, size.x * 0.22)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF8FD17A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, size.x * 0.08)
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 7; i++) {
      final y = size.y - i * size.y / 7;
      final side = i.isEven ? -1.0 : 1.0;
      final x = size.x * 0.5 + side * size.x * 0.22;
      final leaf = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + side * size.x * 0.46,
          y - 8,
          x + side * size.x * 0.62,
          y + 1,
        )
        ..quadraticBezierTo(x + side * size.x * 0.26, y + 6, x, y)
        ..close();
      canvas.drawPath(
        leaf,
        Paint()
          ..color = i.isEven
              ? const Color(0xFF7CBF68)
              : const Color(0xFF9BE17D),
      );
      canvas.drawLine(
        Offset(x, y),
        Offset(x + side * size.x * 0.38, y),
        Paint()
          ..color = const Color(0xFF375F36)
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
  }
}
