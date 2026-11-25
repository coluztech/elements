import 'package:elements/app/theme.dart';
import 'package:elements/game/element_shift_game.dart';
import 'package:elements/models/element_type.dart';
import 'package:elements/services/audio_service.dart';
import 'package:elements/services/game_settings_service.dart';
import 'package:flutter/material.dart';

/// Landscape movement, jump, and element swap controls (§5.1).
class PlayerHud extends StatelessWidget {
  const PlayerHud({super.key, required this.game});

  static const overlayId = 'playerHud';

  final ElementShiftGame game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameSettings,
      builder: (context, _) => SafeArea(
        child: Stack(
          children: [
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'move  ·  jump  ·  collect golden stars  ·  WASD / arrows + space',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ValueListenableBuilder<ElementType>(
                  valueListenable: game.intents.activeElementListenable,
                  builder: (context, activeElement, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'WORLD ${game.loadedLevel?.world ?? 1}  ·  '
                            'LEVEL ${game.loadedLevel?.index ?? 1}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${activeElement.displayName} · Speed '
                            '${(220 * activeElement.speedMultiplier).round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ValueListenableBuilder<int>(
                  valueListenable: game.starsCollected,
                  builder: (context, count, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF171624).withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFD166).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Text(
                        '★  $count / 3',
                        style: const TextStyle(
                          color: Color(0xFFFFD166),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: gameSettings.movePadEdge == MovePadEdge.left
                  ? Alignment.bottomLeft
                  : Alignment.bottomRight,
              child: Padding(
                padding: gameSettings.movePadEdge == MovePadEdge.left
                    ? const EdgeInsets.fromLTRB(16, 0, 0, 16)
                    : const EdgeInsets.fromLTRB(0, 0, 16, 16),
                child: Transform.scale(
                  scale: gameSettings.hudScale,
                  alignment: gameSettings.movePadEdge == MovePadEdge.left
                      ? Alignment.bottomLeft
                      : Alignment.bottomRight,
                  child: _MovePad(game: game),
                ),
              ),
            ),
            Align(
              alignment: gameSettings.movePadEdge == MovePadEdge.left
                  ? Alignment.bottomRight
                  : Alignment.bottomLeft,
              child: Padding(
                padding: gameSettings.movePadEdge == MovePadEdge.left
                    ? const EdgeInsets.fromLTRB(0, 0, 16, 16)
                    : const EdgeInsets.fromLTRB(16, 0, 0, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Transform.scale(
                      scale: gameSettings.hudScale,
                      alignment: Alignment.bottomRight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (game.intents.availableElements.length > 1)
                            gameSettings.controlScheme ==
                                    ControlScheme.quickSwap
                                ? _ElementSwapButtons(game: game)
                                : _ElementWheelButton(game: game),
                          const SizedBox(height: 10),
                          if (game.intents.availableElements.contains(
                            ElementType.wood,
                          )) ...[
                            _AbilityButton(game: game),
                            const SizedBox(height: 8),
                          ],
                          _JumpButton(game: game),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbilityButton extends StatelessWidget {
  const _AbilityButton({required this.game});

  final ElementShiftGame game;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Use element ability',
    child: Tooltip(
      message: 'Use ability (E)',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AudioService.instance.emit(GameAudioEvent.uiConfirmed);
          game.intents.requestAbility();
        },
        child: Container(
          width: 76,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF3D7A3D).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: const Text(
            'ABILITY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ElementSwapButtons extends StatelessWidget {
  const _ElementSwapButtons({required this.game});

  final ElementShiftGame game;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final element in ElementType.values.where(
        game.intents.availableElements.contains,
      ))
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: _ElementButton(game: game, element: element),
        ),
    ],
  );
}

class _ElementWheelButton extends StatelessWidget {
  const _ElementWheelButton({required this.game});

  final ElementShiftGame game;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ElementType>(
    valueListenable: game.intents.activeElementListenable,
    builder: (context, active, _) => FilledButton.icon(
      onPressed: () async {
        AudioService.instance.emit(GameAudioEvent.uiConfirmed);
        final selected = await showModalBottomSheet<ElementType>(
          context: context,
          backgroundColor: const Color(0xFF241F35),
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final element in ElementType.values.where(
                    game.intents.availableElements.contains,
                  ))
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, element),
                      icon: Text(element.iconName),
                      label: Text(element.displayName),
                    ),
                ],
              ),
            ),
          ),
        );
        if (selected != null) game.intents.requestElement(selected);
      },
      icon: Text(active.iconName),
      label: const Text('ELEMENT'),
    ),
  );
}

class _ElementButton extends StatelessWidget {
  const _ElementButton({required this.game, required this.element});

  final ElementShiftGame game;
  final ElementType element;

  IconData get _icon => switch (element) {
    ElementType.fire => Icons.local_fire_department,
    ElementType.water => Icons.water_drop,
    ElementType.earth => Icons.landscape,
    ElementType.wood => Icons.eco,
  };

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ElementType>(
    valueListenable: game.intents.activeElementListenable,
    builder: (context, active, _) {
      final selected = active == element;
      return Semantics(
        button: true,
        selected: selected,
        label: '${element.displayName} element',
        child: Tooltip(
          message: element.displayName,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AudioService.instance.emit(GameAudioEvent.uiConfirmed);
              game.intents.requestElement(element);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(
                  element.coreColor,
                ).withValues(alpha: selected ? 1 : 0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.white38,
                  width: selected ? 3 : 1,
                ),
              ),
              child: gameSettings.colorblindIconMode
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_icon, color: Colors.white, size: 21),
                        Text(
                          element.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                          ),
                        ),
                      ],
                    )
                  : Icon(_icon, color: Colors.white, size: 25),
            ),
          ),
        ),
      );
    },
  );
}

class _MovePad extends StatelessWidget {
  const _MovePad({required this.game});

  final ElementShiftGame game;

  void _setAxisFromLocal(Offset local, Size size) {
    final nx = ((local.dx / size.width) - 0.5) * 2;
    if (nx.abs() < gameSettings.inputDeadzone) {
      game.intents.hudAxis = 0;
    } else {
      game.intents.hudAxis = nx.clamp(-1.0, 1.0).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = Size(168, 120);
    return Semantics(
      label: 'Move',
      button: true,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _setAxisFromLocal(d.localPosition, size),
          onPanUpdate: (d) => _setAxisFromLocal(d.localPosition, size),
          onPanEnd: (_) => game.intents.hudAxis = 0,
          onPanCancel: () => game.intents.hudAxis = 0,
          onTapDown: (d) => _setAxisFromLocal(d.localPosition, size),
          onTapUp: (_) => game.intents.hudAxis = 0,
          onTapCancel: () => game.intents.hudAxis = 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.chevron_left, color: Colors.white, size: 40),
                Icon(Icons.chevron_right, color: Colors.white, size: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JumpButton extends StatelessWidget {
  const _JumpButton({required this.game});

  final ElementShiftGame game;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Tooltip(
        message: 'Jump',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            AudioService.instance.emit(GameAudioEvent.uiConfirmed);
            game.intents.queueJump();
          },
          child: Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kUiAccent.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const Text(
              'JUMP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
