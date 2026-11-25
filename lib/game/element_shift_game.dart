import 'dart:async';

import 'package:elements/game/components/player/player_intents.dart';
import 'package:elements/game/levels/level_loader.dart';
import 'package:elements/game/levels/level_world.dart';
import 'package:elements/models/level_model.dart';
import 'package:elements/models/player_progress_model.dart';
import 'package:elements/services/audio_service.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum GameSceneState { loading, playing, error, levelComplete }

class ElementShiftGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  ElementShiftGame({this.levelId = 'level_w1_01', LevelLoader? levelLoader})
    : _levelLoader = levelLoader ?? LevelLoader();

  final String levelId;
  final LevelLoader _levelLoader;
  final PlayerIntents intents = PlayerIntents();
  final ValueNotifier<GameSceneState> sceneState = ValueNotifier(
    GameSceneState.loading,
  );
  final ValueNotifier<LevelResult?> levelResult = ValueNotifier(null);
  final ValueNotifier<int> starsCollected = ValueNotifier(0);
  final ValueNotifier<String?> tutorialHint = ValueNotifier(null);

  String? loadError;
  LevelModel? loadedLevel;
  LevelWorld? currentLevelWorld;

  @override
  Color backgroundColor() => const Color(0xFF1A1625);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    await loadLevel(levelId);
  }

  Future<void> loadLevel(String requestedLevelId) async {
    sceneState.value = GameSceneState.loading;
    loadError = null;
    levelResult.value = null;
    starsCollected.value = 0;
    tutorialHint.value = null;
    try {
      final level = await _levelLoader.load(requestedLevelId);
      unawaited(AudioService.instance.preloadLevelAudio());
      unawaited(AudioService.instance.playWorldMusic(level.world));
      loadedLevel = level;
      tutorialHint.value = level.tutorialHint;
      camera.viewfinder.visibleGameSize = Vector2(level.width, level.height);

      final previousWorld = currentLevelWorld;
      previousWorld?.removeFromParent();
      final nextWorld = LevelWorld(
        level: level,
        intents: intents,
        starsCollected: starsCollected,
        onLevelComplete: (result) {
          levelResult.value = result;
          sceneState.value = GameSceneState.levelComplete;
        },
      );
      currentLevelWorld = nextWorld;
      await world.add(nextWorld);
      sceneState.value = GameSceneState.playing;
    } catch (error) {
      loadError = error.toString();
      sceneState.value = GameSceneState.error;
    }
  }
}
