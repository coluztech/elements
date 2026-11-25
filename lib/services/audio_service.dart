import 'dart:async';

import 'package:elements/models/element_type.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameAudioEvent {
  elementTransformed,
  shardCollected,
  switchActivated,
  levelCompleted,
  playerDied,
  uiConfirmed,
}

/// Owns audio channels and maps gameplay events to pooled sound assets.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const _soundByElement = <ElementType, String>{
    ElementType.fire: 'sfx/transform_fire.wav',
    ElementType.water: 'sfx/transform_water.wav',
    ElementType.earth: 'sfx/transform_earth.wav',
    ElementType.wood: 'sfx/transform_wood.wav',
  };

  static const _musicByWorld = <int, String>{1: 'music/world1.wav'};

  static const _feedbackSounds = <GameAudioEvent, String>{
    GameAudioEvent.shardCollected: 'sfx/collect.wav',
    GameAudioEvent.switchActivated: 'sfx/switch.wav',
    GameAudioEvent.levelCompleted: 'sfx/level_complete.wav',
    GameAudioEvent.playerDied: 'sfx/respawn.wav',
    GameAudioEvent.uiConfirmed: 'sfx/switch.wav',
  };

  final Map<String, AudioPool> _pools = {};
  Future<void>? _initializing;
  Future<void>? _preloading;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;
  double uiVolume = 0.8;
  int? _activeWorld;
  Timer? _volumeSaveTimer;
  final Map<String, double> _pendingVolumes = {};

  Future<void> init() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      musicVolume = preferences.getDouble('audio.musicVolume') ?? musicVolume;
      sfxVolume = preferences.getDouble('audio.sfxVolume') ?? sfxVolume;
      uiVolume = preferences.getDouble('audio.uiVolume') ?? uiVolume;
    } catch (_) {
      // Tests and unsupported platforms keep the in-memory defaults.
    }
  }

  Future<void> preloadLevelAudio() => _preloading ??= _preloadLevelAudio();

  Future<void> _preloadLevelAudio() async {
    await init();
    for (final asset in {
      ..._soundByElement.values,
      ..._feedbackSounds.values,
    }) {
      if (_pools.containsKey(asset)) continue;
      try {
        _pools[asset] = await FlameAudio.createPool(
          asset,
          minPlayers: 1,
          maxPlayers: 1,
        );
      } catch (_) {
        // Missing audio or unsupported audio hardware must not block gameplay.
      }
    }
  }

  void emit(GameAudioEvent event, {ElementType? element}) {
    final asset = switch (event) {
      GameAudioEvent.elementTransformed =>
        element == null ? null : _soundByElement[element],
      _ => _feedbackSounds[event],
    };
    if (asset != null) {
      _play(
        asset,
        volume: event == GameAudioEvent.uiConfirmed ? uiVolume : sfxVolume,
      );
    }
  }

  void playElementTransformed(ElementType element) =>
      emit(GameAudioEvent.elementTransformed, element: element);

  Future<void> _play(String asset, {required double volume}) async {
    try {
      await preloadLevelAudio();
      await _pools[asset]?.start(volume: volume);
    } catch (_) {
      // Playback is best-effort; gameplay never waits on an audio device.
    }
  }

  Future<void> playWorldMusic(int worldId) async {
    await init();
    final track = _musicByWorld[worldId];
    if (track == null) return;
    try {
      await FlameAudio.bgm.initialize();
      final bgm = FlameAudio.bgm;
      if (_activeWorld == worldId && bgm.isPlaying) return;
      if (bgm.isPlaying) {
        for (var step = 8; step > 0; step--) {
          await bgm.audioPlayer.setVolume(musicVolume * step / 8);
          await Future<void>.delayed(const Duration(milliseconds: 60));
        }
      }
      await bgm.play(track, volume: 0);
      for (var step = 1; step <= 8; step++) {
        await bgm.audioPlayer.setVolume(musicVolume * step / 8);
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      _activeWorld = worldId;
    } catch (_) {
      // A missing optional world track leaves the game silent, not broken.
    }
  }

  Future<void> setMusicVolume(double value) =>
      _setVolume('audio.musicVolume', value, (v) {
        musicVolume = v;
        if (FlameAudio.bgm.isPlaying) {
          FlameAudio.bgm.audioPlayer.setVolume(v).ignore();
        }
      });

  Future<void> setSfxVolume(double value) =>
      _setVolume('audio.sfxVolume', value, (v) => sfxVolume = v);

  Future<void> setUiVolume(double value) =>
      _setVolume('audio.uiVolume', value, (v) => uiVolume = v);

  Future<void> _setVolume(
    String key,
    double value,
    void Function(double) apply,
  ) async {
    final normalized = value.clamp(0.0, 1.0).toDouble();
    apply(normalized);
    _pendingVolumes[key] = normalized;
    _volumeSaveTimer?.cancel();
    _volumeSaveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final preferences = await SharedPreferences.getInstance();
        for (final entry in _pendingVolumes.entries) {
          await preferences.setDouble(entry.key, entry.value);
        }
        _pendingVolumes.clear();
      } catch (_) {
        // Keep the live volume even if the platform preference store is absent.
      }
    });
  }
}
