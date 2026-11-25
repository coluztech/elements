import 'package:elements/models/element_type.dart';

enum ElementSwitchType { fire, water, earth, universal }

class SwitchActivationResolver {
  SwitchActivationResolver._();

  static bool isActivatedByPlayer(
    ElementSwitchType switchType,
    ElementType element,
  ) => switch (switchType) {
    ElementSwitchType.fire => element == ElementType.fire,
    ElementSwitchType.water => element == ElementType.water,
    ElementSwitchType.earth => element == ElementType.earth,
    ElementSwitchType.universal => true,
  };

  static bool isHeldByCrate(ElementSwitchType switchType) =>
      switchType == ElementSwitchType.earth;
}
