import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/components/terrain/solid_block.dart';
import 'package:elements/models/element_type.dart';
import 'package:flutter/material.dart';

class EarthPlatform extends SolidBlock {
  EarthPlatform({
    required super.position,
    required super.size,
    required this.player,
  }) : super(fill: const Color(0xFF8A5A32));

  final PlayerComponent player;

  @override
  void update(double dt) {
    super.update(dt);
    final center = absolutePosition + size / 2;
    final playerCenter = player.position + player.size / 2;
    final withinRange = center.distanceTo(playerCenter) <= 150;
    isSolid = player.lifeState == PlayerLifeState.alive &&
        player.element == ElementType.earth && withinRange;
  }
}
