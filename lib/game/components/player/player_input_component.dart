import 'package:elements/game/components/player/player_intents.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

class PlayerInputComponent extends Component with KeyboardHandler {
  PlayerInputComponent(this.intents);

  final PlayerIntents intents;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final left =
        keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    final right =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);
    intents.keyboardAxis = (right ? 1.0 : 0.0) + (left ? -1.0 : 0.0);

    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.keyW)) {
      intents.queueJump();
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
      intents.requestAbility();
    }
    return true;
  }
}
