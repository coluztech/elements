import 'dart:math' as math;

import 'package:elements/game/components/terrain/solid_block.dart';
import 'package:flutter/material.dart';

class PushableCrate extends SolidBlock {
  PushableCrate({required super.position, required super.size})
    : super(fill: const Color(0xFF8A5A32));

  bool tryPush(
    double deltaX, {
    required Iterable<SolidBlock> staticSolids,
    required Iterable<PushableCrate> crates,
  }) {
    if (!isSolid || deltaX == 0) return false;
    final nextRect = toAbsoluteRect().shift(Offset(deltaX, 0));
    final hitsTerrain = staticSolids.any(
      (solid) => solid.isSolid && nextRect.overlaps(solid.toAbsoluteRect()),
    );
    final hitsCrate = crates.any(
      (crate) =>
          crate != this &&
          crate.isSolid &&
          nextRect.overlaps(crate.toAbsoluteRect()),
    );
    if (hitsTerrain || hitsCrate) return false;
    position.x += deltaX;
    _pushMotion = 0.12;
    return true;
  }

  double _pushMotion = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _pushMotion = math.max(0, _pushMotion - dt);
  }

  @override
  void render(Canvas canvas) {
    if (!isSolid) return;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final frame = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      frame.shift(const Offset(0, 2)),
      Paint()..color = const Color(0xFF2E211D).withValues(alpha: 0.4),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC98A4B), Color(0xFF87502F)],
        ).createShader(rect),
    );
    final plankWidth = size.x / 3;
    for (var i = 0; i < 3; i++) {
      final plank = Rect.fromLTWH(
        4 + i * plankWidth,
        4,
        plankWidth - 2,
        size.y - 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(plank, const Radius.circular(2)),
        Paint()
          ..color =
              (i.isEven ? const Color(0xFFB9783F) : const Color(0xFFA96A3B))
                  .withValues(alpha: 0.86),
      );
      canvas.drawLine(
        Offset(plank.left + 4, size.y * 0.32),
        Offset(plank.right - 4, size.y * 0.32),
        Paint()
          ..color = const Color(0xFFE2A96A).withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(plank.left + 4, size.y * 0.68),
        Offset(plank.right - 4, size.y * 0.68),
        Paint()
          ..color = const Color(0xFF704329).withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
    }
    final border = Paint()
      ..color = const Color(0xFF563622)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(frame, border);
    final postPaint = Paint()
      ..color = const Color(0xFFD5A064)
      ..strokeWidth = math.max(5, size.x * 0.12);
    for (final x in [size.x * 0.1, size.x * 0.9]) {
      canvas.drawLine(Offset(x, 3), Offset(x, size.y - 3), postPaint);
    }
    final nailPaint = Paint()..color = const Color(0xFF513B31);
    for (final x in [size.x * 0.1, size.x * 0.9]) {
      for (final y in [size.y * 0.18, size.y * 0.82]) {
        canvas.drawCircle(Offset(x, y), 1.8, nailPaint);
      }
    }
    if (_pushMotion > 0) {
      final pulse = _pushMotion / 0.12;
      canvas.drawRRect(
        frame,
        Paint()
          ..color = const Color(0xFFFFD28D).withValues(alpha: pulse * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}
