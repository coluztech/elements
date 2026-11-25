import 'dart:math' as math;

import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/components/structures/temporary_wood_structure.dart';
import 'package:elements/game/components/terrain/solid_block.dart';
import 'package:elements/models/element_type.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WoodAnchor extends PositionComponent {
  WoodAnchor({
    required Vector2 position,
    required Vector2 structureSize,
    required this.durationSeconds,
    required this.solids,
    required this.climbableVines,
  }) : structureSize = structureSize.clone(),
       super(position: position, size: Vector2(32, 32), anchor: Anchor.topLeft);

  final Vector2 structureSize;
  final double durationSeconds;
  final List<SolidBlock> solids;
  final List<TemporaryWoodStructure> climbableVines;
  TemporaryWoodStructure? _structure;
  double _pulseTime = 0;

  Future<bool> activateFor(PlayerComponent player) async {
    if (player.element != ElementType.wood ||
        player.lifeState != PlayerLifeState.alive) {
      return false;
    }
    if ((player.position + player.size / 2).distanceTo(
          absolutePosition + size / 2,
        ) >
        150) {
      return false;
    }
    if (_structure?.isSolid ?? false) return false;
    final structure = TemporaryWoodStructure(
      position: absolutePosition.clone(),
      size: structureSize.clone(),
      durationSeconds: durationSeconds,
    )..beginDecay();
    _structure = structure;
    if (structure.size.y > structure.size.x) {
      climbableVines.add(structure);
    } else {
      solids.add(structure);
    }
    await parent?.add(structure);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final pulse = 0.55 + 0.25 * (0.5 + 0.5 * math.sin(_pulseTime * 5));
    canvas.drawCircle(
      rect.center,
      12,
      Paint()..color = const Color(0xFF8FD17A).withValues(alpha: pulse),
    );
    canvas.drawCircle(rect.center, 6, Paint()..color = const Color(0xFF3D7A3D));
  }
}
