import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ControlScheme { quickSwap, elementWheel }

enum MovePadEdge { left, right }

class GameSettingsService extends ChangeNotifier {
  ControlScheme controlScheme = ControlScheme.quickSwap;
  MovePadEdge movePadEdge = MovePadEdge.left;
  double hudScale = 1;
  double inputDeadzone = 0.18;
  bool hapticsEnabled = true;
  bool colorblindIconMode = true;
  Timer? _saveTimer;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      controlScheme =
          ControlScheme.values[(prefs.getInt('settings.controlScheme') ?? 0)
              .clamp(0, 1)
              .toInt()];
      movePadEdge =
          MovePadEdge.values[(prefs.getInt('settings.movePadEdge') ?? 0)
              .clamp(0, 1)
              .toInt()];
      hudScale = (prefs.getDouble('settings.hudScale') ?? 1).clamp(0.75, 1.4);
      inputDeadzone = (prefs.getDouble('settings.inputDeadzone') ?? 0.18).clamp(
        0.05,
        0.5,
      );
      hapticsEnabled = prefs.getBool('settings.hapticsEnabled') ?? true;
      colorblindIconMode = prefs.getBool('settings.colorblindIconMode') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  void update({
    ControlScheme? controlScheme,
    MovePadEdge? movePadEdge,
    double? hudScale,
    double? inputDeadzone,
    bool? hapticsEnabled,
    bool? colorblindIconMode,
  }) {
    this.controlScheme = controlScheme ?? this.controlScheme;
    this.movePadEdge = movePadEdge ?? this.movePadEdge;
    this.hudScale = hudScale?.clamp(0.75, 1.4).toDouble() ?? this.hudScale;
    this.inputDeadzone =
        inputDeadzone?.clamp(0.05, 0.5).toDouble() ?? this.inputDeadzone;
    this.hapticsEnabled = hapticsEnabled ?? this.hapticsEnabled;
    this.colorblindIconMode = colorblindIconMode ?? this.colorblindIconMode;
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('settings.controlScheme', controlScheme.index);
      await prefs.setInt('settings.movePadEdge', movePadEdge.index);
      await prefs.setDouble('settings.hudScale', hudScale);
      await prefs.setDouble('settings.inputDeadzone', inputDeadzone);
      await prefs.setBool('settings.hapticsEnabled', hapticsEnabled);
      await prefs.setBool('settings.colorblindIconMode', colorblindIconMode);
    } catch (_) {}
  }
}

final gameSettings = GameSettingsService();
