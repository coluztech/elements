import 'package:elements/game/element_shift_game.dart';
import 'package:elements/shell/game/player_hud.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:elements/state/progress_provider.dart';
import 'package:elements/models/player_progress_model.dart';
import 'package:elements/models/world_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.levelId});

  final String levelId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final ElementShiftGame _game = ElementShiftGame(levelId: widget.levelId);
  bool _saveStarted = false;
  Future<void> _completionSave = Future<void>.value();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _game.levelResult.addListener(_onLevelResultChanged);
    _loadEquippedSkins();
  }

  Future<void> _loadEquippedSkins() async {
    try {
      final progress = await ref.read(saveServiceProvider).getProgress();
      _game.intents.equippedSkins = progress.equippedSkins;
    } catch (_) {
      // Cosmetics are optional; a save read failure must not block gameplay.
    }
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelId == widget.levelId) return;
    _saveStarted = false;
    _completionSave = Future<void>.value();
    _game.loadLevel(widget.levelId);
  }

  void _onLevelResultChanged() {
    if (_game.levelResult.value != null) {
      _completionSave = _persistCompletion();
    }
  }

  Future<void> _persistCompletion() async {
    final result = _game.levelResult.value;
    final level = _game.loadedLevel;
    if (_saveStarted || result == null || level == null) return;
    _saveStarted = true;
    try {
      await ref
          .read(saveServiceProvider)
          .recordLevelResult(level.levelId, result);
      if (mounted) ref.invalidate(progressProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Progress could not be saved: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _game.onRemove();
    _game.levelResult.removeListener(_onLevelResultChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget<ElementShiftGame>(
            game: _game,
            autofocus: true,
            overlayBuilderMap: {
              PlayerHud.overlayId: (context, game) => ValueListenableBuilder(
                valueListenable: game.sceneState,
                builder: (context, sceneState, _) =>
                    sceneState == GameSceneState.playing
                    ? PlayerHud(game: game)
                    : const SizedBox.shrink(),
              ),
            },
            initialActiveOverlays: const [PlayerHud.overlayId],
          ),
          Positioned.fill(
            child: ValueListenableBuilder<GameSceneState>(
              valueListenable: _game.sceneState,
              builder: (context, sceneState, _) => switch (sceneState) {
                GameSceneState.loading => const _LoadingOverlay(),
                GameSceneState.error => _LevelLoadError(
                  message: _game.loadError ?? 'Unknown level loading error.',
                  onRetry: () => _game.loadLevel(widget.levelId),
                ),
                GameSceneState.levelComplete => _LevelCompleteOverlay(
                  result: _game.levelResult.value,
                  continueLabel: _hasNextLevel ? 'Next Level' : 'Root Map',
                  onRetry: () {
                    _saveStarted = false;
                    _completionSave = Future<void>.value();
                    _game.loadLevel(widget.levelId);
                  },
                  onNext: _continueAfterSave,
                ),
                GameSceneState.playing => const SizedBox.shrink(),
              },
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 48, left: 100, right: 100),
                child: ValueListenableBuilder<String?>(
                  valueListenable: _game.tutorialHint,
                  builder: (context, hint, _) => hint == null
                      ? const SizedBox.shrink()
                      : _TutorialHintCard(
                          hint: hint,
                          onDismiss: () => _game.tutorialHint.value = null,
                        ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Pause',
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.pause, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueAfterSave() async {
    await _completionSave;
    if (!mounted) return;
    final level = _game.loadedLevel;
    if (level == null) return;
    final world = launchWorlds.where((item) => item.id == level.world);
    if (world.isNotEmpty && level.index < world.first.levelCount) {
      final nextId =
          'level_w${level.world}_${(level.index + 1).toString().padLeft(2, '0')}';
      context.go('/play/$nextId');
      return;
    }
    context.go('/');
  }

  bool get _hasNextLevel {
    final level = _game.loadedLevel;
    if (level == null) return false;
    return launchWorlds.any(
      (world) => world.id == level.world && level.index < world.levelCount,
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black.withValues(alpha: 0.72),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading level…', style: TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );
}

class _LevelLoadError extends StatelessWidget {
  const _LevelLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black.withValues(alpha: 0.82),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Could not load level',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LevelCompleteOverlay extends StatelessWidget {
  const _LevelCompleteOverlay({
    required this.result,
    required this.continueLabel,
    required this.onRetry,
    required this.onNext,
  });

  final LevelResult? result;
  final String continueLabel;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black.withValues(alpha: 0.72),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Level complete',
            style: TextStyle(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: 12),
          Text(
            '★' * (result?.stars ?? 1) + '☆' * (3 - (result?.stars ?? 1)),
            style: const TextStyle(color: Color(0xFFFFD166), fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            'Shards ${result?.shardsCollected ?? 0}/${result?.totalShards ?? 0}'
            '  ·  ${((result?.bestTimeMs ?? 0) / 1000).toStringAsFixed(1)}s'
            '  ·  ${result?.minSwaps ?? 0} swaps',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Golden stars collected: ${result?.stars ?? 0}/3',
            style: const TextStyle(color: Color(0xFFFFD166)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
              FilledButton(onPressed: onNext, child: Text(continueLabel)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TutorialHintCard extends StatelessWidget {
  const _TutorialHintCard({required this.hint, required this.onDismiss});

  final String hint;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF241F35).withValues(alpha: 0.96),
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFFFD166)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(hint, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 6),
          TextButton(onPressed: onDismiss, child: const Text('Got it')),
        ],
      ),
    ),
  );
}
