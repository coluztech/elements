import 'package:elements/models/element_type.dart';
import 'package:flutter/foundation.dart';

/// Cross-source input for the player: HUD (touch) + keyboard.
class PlayerIntents {
  double hudAxis = 0;
  double keyboardAxis = 0;
  ElementType activeElement = ElementType.fire;
  Map<String, String> equippedSkins = const {};
  Set<ElementType> availableElements = ElementType.values.toSet();
  final activeElementListenable = ValueNotifier<ElementType>(ElementType.fire);
  void Function(ElementType element)? onElementRequested;
  void Function()? onAbilityRequested;

  static const jumpBuffer = 0.12;

  double? _jumpAge;

  double get horizontal => (hudAxis + keyboardAxis).clamp(-1.0, 1.0).toDouble();

  void requestElement(ElementType element) => onElementRequested?.call(element);

  void requestAbility() => onAbilityRequested?.call();

  void queueJump() => _jumpAge = 0;

  bool get hasBufferedJump => _jumpAge != null;

  void tick(double dt, {bool preserveJump = false}) {
    if (_jumpAge == null) {
      return;
    }
    if (preserveJump) return;
    _jumpAge = _jumpAge! + dt;
    if (_jumpAge! > jumpBuffer) {
      _jumpAge = null;
    }
  }

  bool consumeJump() {
    if (_jumpAge == null) {
      return false;
    }
    _jumpAge = null;
    return true;
  }
}
