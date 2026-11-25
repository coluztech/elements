import 'dart:ui';

import 'package:elements/game/components/interactables/pushable_crate.dart';
import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/systems/player_kinematics.dart';
import 'package:elements/models/element_type.dart';
import 'package:flame/components.dart';

class PlayerPhysicsComponent extends Component {
  @override
  void update(double dt) {
    final player = parent;
    if (player is! PlayerComponent) {
      return;
    }
    if (player.lifeState != PlayerLifeState.alive) return;
    player.stateMachine.update(dt);
    player.isPushing = false;
    _pushCrates(player, dt);
    Rect? swimmingVolume;
    if (player.element == ElementType.water) {
      for (final volume in player.waterVolumes) {
        if (volume.overlaps(player.body.aabb)) {
          swimmingVolume = volume;
          break;
        }
      }
    }
    final inWater = swimmingVolume != null;
    player.isSwimming = inWater;
    player.isClimbing =
        player.element == ElementType.wood &&
        player.intents.horizontal.abs() > 0.1 &&
        player.climbableVines.any(
          (vine) =>
              vine.isSolid && vine.toAbsoluteRect().overlaps(player.body.aabb),
        );
    player.intents.tick(dt, preserveJump: player.stateMachine.isSwapping);
    final jumped = PlayerKinematics.step(
      body: player.body,
      config: player.config,
      dt: dt,
      horizontal: player.intents.horizontal,
      jumpRequested: player.intents.hasBufferedJump,
      solids: player.solidAabbs,
      element: player.element,
      inWater: inWater,
      waterSurfaceY: swimmingVolume?.top,
      climbing: player.isClimbing,
      applyElementStats: player.availableElements?.isNotEmpty ?? true,
    );
    if (jumped) {
      player.intents.consumeJump();
    }
    player.position.setValues(player.body.x, player.body.y);
    final world = player.parent;
    if (world is PositionComponent && player.body.y > world.size.y) {
      player.beginRespawn();
    }
  }

  void _pushCrates(PlayerComponent player, double dt) {
    if (player.element != ElementType.earth || player.intents.horizontal == 0) {
      return;
    }
    final deltaX =
        player.intents.horizontal *
        player.config.moveSpeed *
        player.element.speedMultiplier *
        dt.clamp(0.0, player.config.maxStep);
    if (deltaX == 0) return;

    final nextPlayerRect = player.body.aabb.shift(Offset(deltaX, 0));
    for (final crate in player.pushableCrates) {
      if (!crate.isSolid || !nextPlayerRect.overlaps(crate.toAbsoluteRect())) {
        continue;
      }
      final pushed = crate.tryPush(
        deltaX,
        staticSolids: player.solids.where(
          (solid) => solid.isSolid && solid is! PushableCrate,
        ),
        crates: player.pushableCrates,
      );
      if (pushed) {
        player.isPushing = true;
        player.visual.playPush(player.intents.horizontal.sign.toInt());
      }
    }
  }
}
