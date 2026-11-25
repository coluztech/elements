import 'dart:async';

import 'package:elements/game/components/hazards/electric_hazard.dart';
import 'package:elements/game/components/hazards/fire_hazard.dart';
import 'package:elements/game/components/hazards/water_hazard.dart';
import 'package:elements/game/components/interactables/checkpoint_component.dart';
import 'package:elements/game/components/interactables/burnable_vine.dart';
import 'package:elements/game/components/interactables/element_shard_component.dart';
import 'package:elements/game/components/interactables/collectible_star_component.dart';
import 'package:elements/game/components/interactables/goal_component.dart';
import 'package:elements/game/components/interactables/element_switch_component.dart';
import 'package:elements/game/components/interactables/pushable_crate.dart';
import 'package:elements/game/components/interactables/water_volume_component.dart';
import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/components/player/player_intents.dart';
import 'package:elements/game/components/terrain/solid_block.dart';
import 'package:elements/game/components/terrain/level_backdrop.dart';
import 'package:elements/game/systems/checkpoint_system.dart';
import 'package:elements/game/systems/objective_system.dart';
import 'package:elements/game/components/structures/earth_platform.dart';
import 'package:elements/game/components/structures/temporary_wood_structure.dart';
import 'package:elements/game/components/structures/wood_anchor.dart';
import 'package:elements/models/level_model.dart';
import 'package:elements/models/element_type.dart';
import 'package:elements/services/audio_service.dart';
import 'package:elements/models/player_progress_model.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LevelWorld extends PositionComponent {
  LevelWorld({
    required this.level,
    required this.intents,
    required this.starsCollected,
    required this.onLevelComplete,
  }) : super(size: Vector2(level.width, level.height), anchor: Anchor.topLeft);

  final LevelModel level;
  final PlayerIntents intents;
  final ValueNotifier<int> starsCollected;
  final void Function(LevelResult result) onLevelComplete;
  final List<SolidBlock> _solids = [];
  final List<PushableCrate> _crates = [];
  final List<WoodAnchor> _woodAnchors = [];
  final List<TemporaryWoodStructure> _woodVines = [];
  final List<Rect> _waterVolumes = [];
  late final ObjectiveSystem _objectives;

  @override
  void update(double dt) {
    super.update(dt);
    if (isMounted) _objectives.update(dt);
  }

  Future<void> _addSolid(LevelRect rect) async {
    final block = SolidBlock(
      position: Vector2(rect.x, rect.y),
      size: Vector2(rect.width, rect.height),
    );
    _solids.add(block);
    await add(block);
  }

  @override
  Future<void> onLoad() async {
    await add(LevelBackdrop(size: size));

    for (final terrain in level.terrain) {
      await _addSolid(terrain);
    }

    for (final hazard in level.hazards) {
      final position = Vector2(hazard.x, hazard.y);
      final hazardSize = Vector2(hazard.width, hazard.height);
      switch (hazard.type) {
        case 'fireHazard':
          await add(FireHazard(position: position, size: hazardSize));
          break;
        case 'waterHazard':
          await add(WaterHazard(position: position, size: hazardSize));
          break;
        case 'electricHazard':
          await add(
            ElectricHazard(
              position: position,
              size: hazardSize,
              isLive: hazard.isLive,
            ),
          );
          break;
      }
    }

    final playerStart = Vector2(level.playerStart.x, level.playerStart.y);
    final initialElement = level.availableElements.isNotEmpty
        ? level.availableElements.first
        : ElementType.fire;
    final checkpoints = CheckpointSystem(
      playerStart: playerStart,
      initialElement: initialElement,
    );
    _objectives = ObjectiveSystem(
      totalShards: level.shards.length,
      totalStars: level.stars.length,
    );
    final player = PlayerComponent(
      intents: intents,
      solids: _solids,
      pushableCrates: _crates,
      availableElements: level.availableElements,
      waterVolumes: _waterVolumes,
      climbableVines: _woodVines,
      onSwap: _objectives.recordSwap,
      checkpointSystem: checkpoints,
      position: playerStart,
    );

    for (final item in level.interactables.where(
      (item) => item.type == 'crate',
    )) {
      final crate = PushableCrate(
        position: Vector2(item.x, item.y),
        size: Vector2(item.width, item.height),
      );
      _crates.add(crate);
      _solids.add(crate);
      await add(crate);
    }

    for (final item in level.interactables.where(
      (item) => item.type != 'crate',
    )) {
      final itemPosition = Vector2(item.x, item.y);
      final itemSize = Vector2(item.width, item.height);
      switch (item.type) {
        case 'crate':
          break;
        case 'fireSwitch':
        case 'waterSwitch':
        case 'earthSwitch':
        case 'universalSwitch':
          await add(
            ElementSwitchComponent(
              type: item.type,
              position: itemPosition,
              size: itemSize,
              player: player,
              crates: _crates,
              crateOnly: item.crateOnly,
            ),
          );
          break;
        case 'woodAnchor':
          final anchor = WoodAnchor(
            position: itemPosition,
            structureSize: itemSize,
            durationSeconds: item.durationSeconds,
            solids: _solids,
            climbableVines: _woodVines,
          );
          _woodAnchors.add(anchor);
          await add(anchor);
          break;
        case 'earthAnchor':
          final platform = EarthPlatform(
            position: itemPosition,
            size: itemSize,
            player: player,
          );
          _solids.add(platform);
          await add(platform);
          break;
        case 'burnableVine':
          final vine = BurnableVine(
            position: itemPosition,
            size: itemSize,
            player: player,
          );
          _solids.add(vine);
          await add(vine);
          break;
        case 'waterVolume':
          _waterVolumes.add(
            Rect.fromLTWH(item.x, item.y, item.width, item.height),
          );
          await add(
            WaterVolumeComponent(position: itemPosition, size: itemSize),
          );
          break;
      }
    }

    intents.onAbilityRequested = () {
      if (player.element == ElementType.wood &&
          player.lifeState == PlayerLifeState.alive) {
        player.visual.playAbility(ElementType.wood);
      }
      for (final anchor in _woodAnchors) {
        unawaited(anchor.activateFor(player));
      }
    };
    for (final checkpoint in level.checkpoints) {
      final respawnPosition = Vector2(checkpoint.x, checkpoint.y);
      await add(
        CheckpointComponent(
          position: Vector2(checkpoint.x + 4, checkpoint.y - 28),
          respawnPosition: respawnPosition,
        ),
      );
    }

    await add(
      GoalComponent(
        position: Vector2(level.goal.x, level.goal.y),
        size: Vector2(level.goal.width, level.goal.height),
        onReached: () => onLevelComplete(_objectives.complete()),
      ),
    );

    for (final shard in level.shards) {
      await add(
        ElementShardComponent(
          position: Vector2(shard.x, shard.y),
          onCollected: () {
            _objectives.collectShard();
            AudioService.instance.emit(GameAudioEvent.shardCollected);
          },
        ),
      );
    }

    for (final star in level.stars) {
      await add(
        CollectibleStarComponent(
          position: Vector2(star.x, star.y),
          onCollected: () {
            _objectives.collectStar();
            starsCollected.value = _objectives.starsCollected;
            AudioService.instance.emit(GameAudioEvent.shardCollected);
          },
        ),
      );
    }

    await add(player);
  }
}
