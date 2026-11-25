import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ControlScheme { quickSwap, elementWheel }

class SettingsState {
  const SettingsState({
    this.controlScheme = ControlScheme.quickSwap,
    this.hudScale = 1.0,
    this.hapticEnabled = true,
    this.musicVolume = 1.0,
    this.sfxVolume = 1.0,
    this.uiVolume = 1.0,
    this.colorblindIconMode = false,
  });

  final ControlScheme controlScheme;
  final double hudScale;
  final bool hapticEnabled;
  final double musicVolume;
  final double sfxVolume;
  final double uiVolume;
  final bool colorblindIconMode;
}

final settingsProvider = Provider<SettingsState>((ref) => const SettingsState());
