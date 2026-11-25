import 'dart:async';

import 'package:elements/services/audio_service.dart';
import 'package:elements/services/game_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _audio = AudioService.instance;

  @override
  void initState() {
    super.initState();
    _loadAudioPreferences();
    gameSettings.load();
  }

  Future<void> _loadAudioPreferences() async {
    await _audio.init();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListenableBuilder(
        listenable: gameSettings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Audio', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Adjust each sound channel independently. Changes are saved automatically.',
            ),
            const SizedBox(height: 20),
            Text(
              'Controls & accessibility',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SwitchListTile(
              title: const Text('Element wheel controls'),
              subtitle: const Text(
                'Use one large element selector instead of quick-swap buttons.',
              ),
              value: gameSettings.controlScheme == ControlScheme.elementWheel,
              onChanged: (enabled) => gameSettings.update(
                controlScheme: enabled
                    ? ControlScheme.elementWheel
                    : ControlScheme.quickSwap,
              ),
            ),
            ListTile(
              title: const Text('Movement pad position'),
              trailing: SegmentedButton<MovePadEdge>(
                segments: const [
                  ButtonSegment(value: MovePadEdge.left, label: Text('Left')),
                  ButtonSegment(value: MovePadEdge.right, label: Text('Right')),
                ],
                selected: {gameSettings.movePadEdge},
                onSelectionChanged: (value) =>
                    gameSettings.update(movePadEdge: value.first),
              ),
            ),
            _VolumeSlider(
              label: 'HUD size',
              icon: Icons.zoom_out_map,
              value: (gameSettings.hudScale - 0.75) / 0.65,
              onChanged: (value) =>
                  gameSettings.update(hudScale: 0.75 + value * 0.65),
              valueText: '${(gameSettings.hudScale * 100).round()}%',
            ),
            _VolumeSlider(
              label: 'Input deadzone',
              icon: Icons.gamepad,
              value: (gameSettings.inputDeadzone - 0.05) / 0.45,
              onChanged: (value) =>
                  gameSettings.update(inputDeadzone: 0.05 + value * 0.45),
              valueText: '${(gameSettings.inputDeadzone * 100).round()}%',
            ),
            SwitchListTile(
              title: const Text('Haptic feedback'),
              value: gameSettings.hapticsEnabled,
              onChanged: (value) => gameSettings.update(hapticsEnabled: value),
            ),
            SwitchListTile(
              title: const Text('Element icons for colorblind support'),
              value: gameSettings.colorblindIconMode,
              onChanged: (value) =>
                  gameSettings.update(colorblindIconMode: value),
            ),
            const Divider(height: 36),
            _VolumeSlider(
              label: 'Music',
              icon: Icons.music_note,
              value: _audio.musicVolume,
              onChanged: (value) => _setVolume(_audio.setMusicVolume, value),
            ),
            _VolumeSlider(
              label: 'Sound effects',
              icon: Icons.graphic_eq,
              value: _audio.sfxVolume,
              onChanged: (value) => _setVolume(_audio.setSfxVolume, value),
            ),
            _VolumeSlider(
              label: 'Interface',
              icon: Icons.touch_app,
              value: _audio.uiVolume,
              onChanged: (value) => _setVolume(_audio.setUiVolume, value),
            ),
          ],
        ),
      ),
    );
  }

  void _setVolume(Future<void> Function(double) setter, double value) {
    unawaited(setter(value));
    setState(() {});
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.valueText,
  });

  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final String? valueText;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 150,
        child: _LabelWithIcon(label: label, icon: icon),
      ),
      Expanded(
        child: Slider(
          value: value.clamp(0, 1).toDouble(),
          divisions: 10,
          label: '${(value * 100).round()}%',
          onChanged: onChanged,
        ),
      ),
      SizedBox(
        width: 48,
        child: Text(valueText ?? '${(value * 100).round()}%'),
      ),
    ],
  );
}

class _LabelWithIcon extends StatelessWidget {
  const _LabelWithIcon({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
  );
}
