import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:elements/game/components/world_art_cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SolidBlock extends PositionComponent with CollisionCallbacks {
  SolidBlock({
    required Vector2 position,
    required Vector2 size,
    this.fill = const Color(0xFF6B6578),
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  final Color fill;
  bool isSolid = true;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox());
    unawaited(WorldArtCache.preload('tiles/brick_tile.png').catchError((_) {}));
  }

  @override
  void render(Canvas canvas) {
    if (!isSolid) return;
    final rect = size.toRect();
    final tile = WorldArtCache.image('tiles/brick_tile.png');
    if (tile == null) {
      _renderFallbackBricks(canvas, rect);
    } else {
      final scale = 32 / tile.width;
      final matrix = Float64List(16)
        ..[0] = scale
        ..[5] = scale
        ..[10] = 1
        ..[15] = 1;
      final paint = Paint()
        ..shader = ImageShader(
          tile,
          TileMode.repeated,
          TileMode.repeated,
          matrix,
        )
        ..filterQuality = FilterQuality.medium;
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, Paint()..color = fill.withValues(alpha: 0.12));
    }
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF3A3348)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _renderFallbackBricks(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = fill);
    final mortar = Paint()
      ..color = const Color(0xFF332D3B).withValues(alpha: 0.65)
      ..strokeWidth = 2;
    for (var y = 16.0; y < size.y; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), mortar);
    }
    for (var y = 0.0; y < size.y; y += 32) {
      final offset = y % 64 == 0 ? 0.0 : 16.0;
      for (var x = offset + 32; x < size.x; x += 64) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + 32, size.y)),
          mortar,
        );
      }
    }
  }
}
