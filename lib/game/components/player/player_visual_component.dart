import 'dart:async';
import 'dart:math' as math;

import 'package:elements/game/components/player/player_component.dart';
import 'package:elements/models/element_type.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

enum PlayerAnimationState {
  idle,
  run,
  jump,
  fall,
  swim,
  push,
  climb,
  ability,
  transformIn,
  death,
}

/// State-driven procedural animation keeps all four forms animated without
/// making gameplay depend on sprite-sheet assets.
class PlayerVisualComponent extends PositionComponent {
  PlayerVisualComponent() : super(anchor: Anchor.topLeft);

  ElementType _element = ElementType.fire;
  double _burstAge = 1;
  ElementType? _burstElement;
  PlayerAnimationState _animationState = PlayerAnimationState.idle;
  double _animationAge = 0;
  double _abilityAge = 0;
  ElementType? _abilityElement;
  int _pushDirection = 1;
  final Map<ElementType, Sprite> _sprites = {};

  static const _spritePaths = <ElementType, String>{
    ElementType.fire: 'characters/fire.png',
    ElementType.water: 'characters/water.png',
    ElementType.earth: 'characters/earth.png',
    ElementType.wood: 'characters/wood.png',
  };

  @override
  Future<void> onLoad() async {
    final initialElement = (parent as PlayerComponent).element;
    unawaited(_preloadOtherSprites(initialElement).catchError((_) {}));
  }

  Future<void> _preloadOtherSprites(ElementType initialElement) async {
    await _loadSprite(initialElement);
    for (final element in ElementType.values) {
      if (element != initialElement) await _loadSprite(element);
    }
  }

  Future<void> _loadSprite(ElementType element) async {
    if (_sprites.containsKey(element)) return;
    final image = await Flame.images.load(_spritePaths[element]!);
    _sprites[element] = Sprite(image);
  }

  void playTransformIn({required ElementType from, required ElementType to}) {
    assert(from != to);
    _element = to;
    _burstElement = to;
    _burstAge = 0;
    _animationState = PlayerAnimationState.transformIn;
    _animationAge = 0;
  }

  void setElement(ElementType element) => _element = element;

  void playLocomotion(PlayerAnimationState state) {
    if (state == PlayerAnimationState.ability ||
        state == PlayerAnimationState.transformIn ||
        state == PlayerAnimationState.death) {
      return;
    }
    if (_animationState == state) {
      return;
    }
    _animationState = state;
    _animationAge = 0;
  }

  void playAbility(ElementType element) {
    _animationState = PlayerAnimationState.ability;
    _animationAge = 0;
    _abilityAge = 0.42;
    _abilityElement = element;
  }

  void playPush(int direction) {
    if (_animationState != PlayerAnimationState.push) {
      _animationState = PlayerAnimationState.push;
      _animationAge = 0;
    }
    _pushDirection = direction == 0 ? 1 : direction;
  }

  void playDeath() {
    _animationState = PlayerAnimationState.death;
    _animationAge = 0;
  }

  void resetAfterRespawn(ElementType element) {
    _element = element;
    _burstElement = null;
    _burstAge = 1;
    _animationState = PlayerAnimationState.idle;
    _animationAge = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _burstAge = (_burstAge + dt).clamp(0.0, 0.3).toDouble();
    _animationAge += dt;
    _abilityAge = math.max(0, _abilityAge - dt);
    if (_animationState == PlayerAnimationState.transformIn &&
            _burstAge >= 0.3 ||
        _animationState == PlayerAnimationState.ability && _abilityAge <= 0) {
      _animationState = PlayerAnimationState.idle;
      _animationAge = 0;
    }
  }

  @override
  void onMount() {
    super.onMount();
    size = parent is PositionComponent
        ? (parent! as PositionComponent).size
        : size;
  }

  @override
  void render(Canvas canvas) {
    final player = parent;
    final facing = player is PlayerComponent ? player.body.facing : 1;
    final grounded = player is PlayerComponent && player.body.grounded;
    if (player is PlayerComponent) {
      if (player.lifeState == PlayerLifeState.dying ||
          player.lifeState == PlayerLifeState.respawning) {
        if (_animationState != PlayerAnimationState.death) playDeath();
      } else if (!player.stateMachine.isSwapping &&
          _animationState != PlayerAnimationState.ability &&
          _animationState != PlayerAnimationState.death) {
        playLocomotion(
          player.isSwimming
              ? PlayerAnimationState.swim
              : player.isClimbing
              ? PlayerAnimationState.climb
              : player.isPushing
              ? PlayerAnimationState.push
              : !grounded
              ? (player.body.vy < 0
                    ? PlayerAnimationState.jump
                    : PlayerAnimationState.fall)
              : player.body.vx.abs() > 8
              ? PlayerAnimationState.run
              : PlayerAnimationState.idle,
        );
      }
    }
    final stateMachine = player is PlayerComponent ? player.stateMachine : null;
    final element = (stateMachine != null && stateMachine.isSwapping)
        ? stateMachine.targetElement!
        : _element;
    final highlight = Color(element.highlightColor);
    final skinId = player is PlayerComponent
        ? player.intents.equippedSkins[element.name]
        : null;
    final skinTint = switch (skinId) {
      'fire_ember' => const Color(0xFFFFD096),
      'water_glacier' => const Color(0xFFB7F1FF),
      'earth_copper' => const Color(0xFFFFCB8A),
      'wood_jade' => const Color(0xFFB8F2C1),
      _ => null,
    };

    final runCycle = math.sin(_animationAge * 18);
    final bounce = _animationState == PlayerAnimationState.run
        ? runCycle.abs() * 2.4
        : 0.0;
    final isAirborne =
        _animationState == PlayerAnimationState.jump ||
        _animationState == PlayerAnimationState.fall;
    final squashX = _animationState == PlayerAnimationState.run
        ? 1 + runCycle * 0.035
        : isAirborne
        ? 0.94
        : 1.0;
    final squashY = _animationState == PlayerAnimationState.run
        ? 1 - runCycle * 0.04
        : isAirborne
        ? 1.08
        : 1.0;
    final pushLean = _animationState == PlayerAnimationState.push
        ? _pushDirection * (0.08 + 0.045 * math.sin(_animationAge * 13))
        : 0.0;
    final elementMotion = _animationAge * 5;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 + bounce);
    canvas.scale(squashX, squashY);
    if (element == ElementType.fire) {
      canvas.rotate(math.sin(elementMotion * 2) * 0.025);
    } else if (element == ElementType.water && grounded) {
      canvas.translate(0, math.sin(elementMotion) * 1.6);
    } else if (element == ElementType.earth &&
        _animationState == PlayerAnimationState.run) {
      canvas.translate(0, runCycle.abs() * 1.2);
    } else if (element == ElementType.wood &&
        _animationState == PlayerAnimationState.idle) {
      canvas.rotate(math.sin(elementMotion) * 0.018);
    }
    if (_animationState == PlayerAnimationState.push) {
      canvas.rotate(pushLean);
    }
    if (_animationState == PlayerAnimationState.swim) {
      canvas.translate(0, math.sin(elementMotion * 1.6) * 1.2);
      canvas.scale(1.04, 0.96);
    } else if (_animationState == PlayerAnimationState.climb) {
      canvas.rotate(math.sin(elementMotion * 2) * 0.035);
      canvas.translate(0, math.sin(elementMotion * 2) * 1.5);
    }
    canvas.translate(-size.x / 2, -size.y / 2 - bounce);
    final sprite = _sprites[element] ?? _sprites[_element];
    if (sprite == null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 7, size.x - 8, size.y - 9),
          const Radius.circular(10),
        ),
        Paint()..color = Color(element.coreColor),
      );
    } else {
      sprite.render(
        canvas,
        size: Vector2(size.x, size.y),
        overridePaint: Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = skinTint == null
              ? null
              : ColorFilter.mode(skinTint, BlendMode.modulate),
      );
    }
    _renderCosmeticSkin(canvas, skinId, size);
    if (_animationState == PlayerAnimationState.swim) {
      _renderSwimMotion(canvas, highlight);
    } else if (_animationState == PlayerAnimationState.climb) {
      _renderClimbMotion(canvas, highlight);
    } else if (_animationState == PlayerAnimationState.push) {
      _renderPushMotion(canvas, highlight);
    }
    _renderElementParticles(canvas, element, highlight, facing);

    if (stateMachine?.isSwapping ?? false) {
      final progress = stateMachine!.swapProgress;
      final radius = 12 + 28 * progress;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        radius,
        Paint()
          ..color = highlight.withValues(alpha: (1 - progress) * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    if (_burstAge < 0.3 && _burstElement != null) {
      final progress = _burstAge / 0.3;
      final burstPaint = Paint()
        ..color = Color(
          _burstElement!.highlightColor,
        ).withValues(alpha: 1 - progress);
      for (var i = 0; i < 14; i++) {
        final angle = i * (math.pi * 2 / 14);
        final radius = 9 + 31 * progress;
        canvas.drawCircle(
          Offset(
            size.x / 2 + radius * math.cos(angle),
            size.y / 2 + radius * math.sin(angle),
          ),
          2.5 * (1 - progress),
          burstPaint,
        );
      }
    }
    if (_animationState == PlayerAnimationState.ability || _abilityAge > 0) {
      final phase =
          (_animationState == PlayerAnimationState.ability
              ? _animationAge
              : 0.42 - _abilityAge) /
          0.42;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        17 + phase * 19,
        Paint()
          ..color = highlight.withValues(alpha: (1 - phase).clamp(0, 1) * 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      if (_abilityElement == ElementType.fire) {
        final flame = Path()
          ..moveTo(size.x * 0.58, size.y * 0.45)
          ..quadraticBezierTo(
            size.x * 0.95,
            size.y * 0.5,
            size.x * 1.25,
            size.y * 0.28,
          )
          ..quadraticBezierTo(
            size.x * 1.03,
            size.y * 0.62,
            size.x * 0.58,
            size.y * 0.55,
          );
        canvas.drawPath(
          flame,
          Paint()
            ..color = const Color(0xFFFF8A50).withValues(alpha: 0.72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      } else if (_abilityElement == ElementType.wood) {
        for (var i = 0; i < 4; i++) {
          final angle = _animationAge * 8 + i * math.pi / 2;
          canvas.drawCircle(
            Offset(
              size.x / 2 + math.cos(angle) * (16 + _animationAge * 20),
              size.y / 2 + math.sin(angle) * (12 + _animationAge * 18),
            ),
            2.3,
            Paint()..color = highlight.withValues(alpha: 0.9),
          );
        }
      }
    }
    if (_animationState == PlayerAnimationState.death) {
      canvas.drawRect(
        size.toRect(),
        Paint()
          ..color = Colors.black.withValues(
            alpha: (_animationAge * 1.8).clamp(0, 0.6),
          ),
      );
    }
    canvas.restore();
  }

  void _renderClimbMotion(Canvas canvas, Color highlight) {
    final reach = math.sin(_animationAge * 10) * 3;
    final handPaint = Paint()
      ..color = highlight.withValues(alpha: 0.95)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.x * 0.32, size.y * 0.44),
      Offset(size.x * 0.12, size.y * (0.20 + reach / size.y)),
      handPaint,
    );
    canvas.drawLine(
      Offset(size.x * 0.68, size.y * 0.48),
      Offset(size.x * 0.88, size.y * (0.29 - reach / size.y)),
      handPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.x * 0.04, size.y * 0.2, size.x * 0.92, size.y * 0.64),
      math.pi * 0.12,
      math.pi * 0.76,
      false,
      Paint()
        ..color = const Color(0xFF9BE17D).withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _renderCosmeticSkin(Canvas canvas, String? skinId, Vector2 size) {
    if (skinId == null) return;
    final gem = Paint()..color = const Color(0xFFFFF2C4);
    switch (skinId) {
      case 'fire_ember':
        final fire = Paint()..color = const Color(0xFFFFC85A);
        for (var i = 0; i < 3; i++) {
          final x = size.x * (0.34 + i * 0.16);
          final flame = Path()
            ..moveTo(x - 3, size.y * 0.23)
            ..quadraticBezierTo(x - 4, size.y * 0.09, x, size.y * 0.035)
            ..quadraticBezierTo(x + 5, size.y * 0.12, x + 3, size.y * 0.23)
            ..close();
          canvas.drawPath(flame, fire);
          canvas.drawCircle(Offset(x, size.y * 0.2), 1.4, gem);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.x * 0.29, size.y * 0.68, size.x * 0.42, 4),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFFFC85A),
        );
        break;
      case 'water_glacier':
        final ice = Paint()..color = const Color(0xFFB9F6FF);
        for (var i = 0; i < 3; i++) {
          final x = size.x * (0.33 + i * 0.17);
          final crystal = Path()
            ..moveTo(x, size.y * 0.02)
            ..lineTo(x + 3, size.y * 0.14)
            ..lineTo(x, size.y * 0.23)
            ..lineTo(x - 3, size.y * 0.14)
            ..close();
          canvas.drawPath(crystal, ice);
          canvas.drawCircle(Offset(x, size.y * 0.14), 1, gem);
        }
        canvas.drawArc(
          Rect.fromLTWH(
            size.x * 0.17,
            size.y * 0.26,
            size.x * 0.66,
            size.y * 0.5,
          ),
          math.pi * 0.12,
          math.pi * 0.76,
          false,
          Paint()
            ..color = const Color(0xFF9DEBFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        break;
      case 'earth_copper':
        final copper = Paint()..color = const Color(0xFFEBA96C);
        for (final x in [size.x * 0.12, size.x * 0.72]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, size.y * 0.46, size.x * 0.18, size.y * 0.15),
              const Radius.circular(4),
            ),
            copper,
          );
          canvas.drawCircle(Offset(x + size.x * 0.09, size.y * 0.53), 1.6, gem);
        }
        final crest = Path()
          ..moveTo(size.x * 0.5, size.y * 0.34)
          ..lineTo(size.x * 0.58, size.y * 0.43)
          ..lineTo(size.x * 0.5, size.y * 0.52)
          ..lineTo(size.x * 0.42, size.y * 0.43)
          ..close();
        canvas.drawPath(crest, copper);
        canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.43), 2.2, gem);
        break;
      case 'wood_jade':
        final leafPaint = Paint()..color = const Color(0xFF9DF0A8);
        for (var i = 0; i < 3; i++) {
          final x = size.x * (0.32 + i * 0.18);
          final leaf = Path()
            ..moveTo(x, size.y * 0.24)
            ..quadraticBezierTo(x - 8, size.y * 0.13, x, size.y * 0.05)
            ..quadraticBezierTo(x + 8, size.y * 0.12, x, size.y * 0.24)
            ..close();
          canvas.drawPath(leaf, leafPaint);
          canvas.drawLine(
            Offset(x, size.y * 0.21),
            Offset(x, size.y * 0.09),
            Paint()
              ..color = const Color(0xFF477C49)
              ..strokeWidth = 1,
          );
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.x * 0.13, size.y * 0.67, size.x * 0.74, 3),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF8EE6A7),
        );
        break;
    }
  }

  void _renderSwimMotion(Canvas canvas, Color highlight) {
    final cycle = math.sin(_animationAge * 12);
    final armPaint = Paint()
      ..color = highlight.withValues(alpha: 0.95)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var side = -1; side <= 1; side += 2) {
      final shoulder = Offset(size.x * (side < 0 ? 0.28 : 0.72), size.y * 0.48);
      final hand = Offset(
        shoulder.dx + side * (8 + cycle * 5),
        size.y * (0.58 + cycle * 0.12),
      );
      final arm = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(
          shoulder.dx + side * (8 + cycle * 3),
          size.y * (0.42 - cycle * 0.08),
          hand.dx,
          hand.dy,
        );
      canvas.drawPath(arm, armPaint);
    }
    final kick = math.sin(_animationAge * 12 + math.pi / 2) * 4;
    final finPaint = Paint()
      ..color = const Color(0xFFB7F1FF).withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.x * 0.38, size.y * 0.82),
      Offset(size.x * 0.22 - kick, size.y * 0.93),
      finPaint,
    );
    canvas.drawLine(
      Offset(size.x * 0.62, size.y * 0.82),
      Offset(size.x * 0.78 + kick, size.y * 0.93),
      finPaint,
    );
    final bubblePaint = Paint()
      ..color = const Color(0xFFC5F5FF).withValues(alpha: 0.86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var i = 0; i < 3; i++) {
      final rise = (_animationAge * 25 + i * 12) % 26;
      canvas.drawCircle(
        Offset(
          size.x * 0.5 + math.sin(_animationAge * 8 + i) * 10,
          size.y * 0.4 - rise,
        ),
        2 + (i % 2),
        bubblePaint,
      );
    }
  }

  void _renderPushMotion(Canvas canvas, Color highlight) {
    final side = _pushDirection.toDouble();
    final pulse = math.sin(_animationAge * 14).abs();
    final armPaint = Paint()
      ..color = highlight.withValues(alpha: 0.95)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final shoulder = Offset(size.x * 0.52, size.y * 0.52);
    final hand = Offset(size.x * (side > 0 ? 1.03 : -0.03), size.y * 0.57);
    final arm = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..quadraticBezierTo(
        size.x * (side > 0 ? 0.83 : 0.17),
        size.y * (0.42 + pulse * 0.04),
        hand.dx,
        hand.dy,
      );
    canvas.drawPath(arm, armPaint);
    final effortPaint = Paint()
      ..color = const Color(0xFFFFE1A6).withValues(alpha: 0.5 + pulse * 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 2; i++) {
      final x = size.x * (side > 0 ? 0.95 : 0.05) + side * (3 + i * 4);
      final y = size.y * (0.42 + i * 0.13);
      canvas.drawLine(Offset(x, y), Offset(x + side * 4, y - 3), effortPaint);
    }
  }

  void _renderElementParticles(
    Canvas canvas,
    ElementType element,
    Color highlight,
    int facing,
  ) {
    final running = _animationState == PlayerAnimationState.run;
    final phase = _animationAge * 7;
    switch (element) {
      case ElementType.fire:
        final flicker = 0.55 + 0.35 * math.sin(phase * 2).abs();
        for (var i = 0; i < 3; i++) {
          final y = size.y * (0.62 + i * 0.12) - (phase * 12 + i * 11) % 16;
          canvas.drawCircle(
            Offset(size.x * (facing > 0 ? 0.22 : 0.78), y),
            1.2 + flicker,
            Paint()..color = highlight.withValues(alpha: 0.7),
          );
        }
        break;
      case ElementType.water:
        final bob = (phase * 0.5) % (size.y * 0.65);
        canvas.drawCircle(
          Offset(size.x * (facing > 0 ? 0.82 : 0.18), size.y - bob),
          1.6,
          Paint()..color = highlight.withValues(alpha: 0.65),
        );
        if (_animationState == PlayerAnimationState.swim) {
          canvas.drawCircle(
            Offset(size.x * (facing > 0 ? 0.25 : 0.75), size.y * 0.3 - bob),
            2.2,
            Paint()..color = highlight.withValues(alpha: 0.7),
          );
        }
        break;
      case ElementType.earth:
        if (running) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(size.x / 2, size.y - 2),
              width: 18 + runCycleDust(phase) * 4,
              height: 4,
            ),
            Paint()..color = highlight.withValues(alpha: 0.35),
          );
        }
        break;
      case ElementType.wood:
        final sway = math.sin(phase) * 2;
        canvas.drawCircle(
          Offset(size.x * 0.85, 8 + sway),
          2.2,
          Paint()..color = highlight.withValues(alpha: 0.8),
        );
        break;
    }
  }

  double runCycleDust(double phase) => math.sin(phase).abs();
}
