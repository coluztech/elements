import 'package:elements/game/components/interactables/pushable_crate.dart';
import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/game/systems/switch_activation_resolver.dart';
import 'package:elements/services/audio_service.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ElementSwitchComponent extends PositionComponent {
  ElementSwitchComponent({
    required this.type,
    required Vector2 position,
    required Vector2 size,
    required this.player,
    required this.crates,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  final String type;
  final PlayerComponent player;
  final List<PushableCrate> crates;
  bool isActive = false;

  @override
  void update(double dt) {
    super.update(dt);
    final switchRect = Rect.fromLTWH(
      absolutePosition.x,
      absolutePosition.y,
      size.x,
      size.y,
    );
    final switchType = ElementSwitchType.values.byName(
      type.replaceAll('Switch', '').toLowerCase(),
    );
    final crateHeld =
        SwitchActivationResolver.isHeldByCrate(switchType) &&
        crates.any(
          (crate) =>
              crate.isSolid && switchRect.overlaps(crate.toAbsoluteRect()),
        );
    final playerActivates =
        player.lifeState == PlayerLifeState.alive &&
        switchRect.overlaps(player.body.aabb) &&
        SwitchActivationResolver.isActivatedByPlayer(
          switchType,
          player.element,
        );
    final wasActive = isActive;
    isActive = crateHeld || playerActivates;
    if (isActive && !wasActive) {
      AudioService.instance.emit(GameAudioEvent.switchActivated);
    }
  }

  @override
  void render(Canvas canvas) {
    final color = switch (type) {
      'fireSwitch' => const Color(0xFFC0392B),
      'waterSwitch' => const Color(0xFF1F6FB2),
      'earthSwitch' => const Color(0xFF8A5A32),
      _ => const Color(0xFF5B3E96),
    };
    final rect = size.toRect();
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = isActive ? const Color(0xFF8FD17A) : color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
