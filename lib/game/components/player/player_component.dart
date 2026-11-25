import 'package:elements/game/components/interactables/pushable_crate.dart';
import 'package:elements/game/components/player/player_input_component.dart';
import 'package:elements/game/components/player/player_intents.dart';
import 'package:elements/game/components/player/player_physics_component.dart';
import 'package:elements/game/components/player/player_visual_component.dart';
import 'package:elements/game/components/terrain/solid_block.dart';
import 'package:elements/game/components/structures/temporary_wood_structure.dart';
import 'package:elements/game/systems/player_kinematics.dart';
import 'package:elements/game/systems/element_state_machine.dart';
import 'package:elements/game/systems/checkpoint_system.dart';
import 'package:elements/game/systems/hazard_response_resolver.dart';
import 'package:elements/models/element_type.dart';
import 'package:elements/services/audio_service.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:elements/services/game_settings_service.dart';

enum PlayerLifeState { alive, dying, respawning, levelComplete }

class PlayerComponent extends PositionComponent with CollisionCallbacks {
  PlayerComponent({
    required this.intents,
    required this.solids,
    this.pushableCrates = const [],
    this.availableElements,
    this.waterVolumes = const [],
    this.climbableVines = const [],
    this.onSwap,
    required this.checkpointSystem,
    required Vector2 position,
    this.config = const PlayerMotionConfig(),
  }) : super(
         position: position,
         size: Vector2(config.width, config.height),
         anchor: Anchor.topLeft,
         priority: 10,
       ) {
    body = MotionBody(
      x: position.x,
      y: position.y,
      width: config.width,
      height: config.height,
    );
    visual = PlayerVisualComponent();
    stateMachine = ElementStateMachine(
      initialElement: (availableElements?.isNotEmpty ?? false)
          ? availableElements!.first
          : ElementType.fire,
      availableElements: availableElements?.toSet(),
      onTransformed: (from, to) {
        intents.activeElement = to;
        intents.activeElementListenable.value = to;
        visual.playTransformIn(from: from, to: to);
        if (gameSettings.hapticsEnabled) HapticFeedback.selectionClick();
        AudioService.instance.emit(
          GameAudioEvent.elementTransformed,
          element: to,
        );
        onSwap?.call();
      },
    );
    intents.activeElement = stateMachine.currentElement;
    intents.availableElements =
        availableElements?.toSet() ?? ElementType.values.toSet();
    intents.activeElementListenable.value = stateMachine.currentElement;
    intents.onElementRequested = stateMachine.requestSwap;
  }

  final PlayerIntents intents;
  final List<SolidBlock> solids;
  final List<PushableCrate> pushableCrates;
  final List<ElementType>? availableElements;
  final List<Rect> waterVolumes;
  final List<TemporaryWoodStructure> climbableVines;
  final void Function()? onSwap;
  final CheckpointSystem checkpointSystem;
  final PlayerMotionConfig config;
  late final MotionBody body;
  late final PlayerVisualComponent visual;
  late final ElementStateMachine stateMachine;
  ElementType get element => stateMachine.currentElement;
  PlayerLifeState lifeState = PlayerLifeState.alive;
  bool isSwimming = false;
  bool isPushing = false;
  bool isClimbing = false;
  double _lifeStateTimer = 0;

  bool requestElement(ElementType element) => stateMachine.requestSwap(element);

  void handleHazardOutcome(HazardOutcome outcome) {
    if (lifeState != PlayerLifeState.alive) return;
    switch (outcome) {
      case HazardOutcome.passThrough:
      case HazardOutcome.extinguishesHazard:
      case HazardOutcome.floats:
        return;
      case HazardOutcome.respawn:
      case HazardOutcome.sinksThenRespawn:
        beginRespawn();
        return;
    }
  }

  void beginRespawn() {
    if (lifeState != PlayerLifeState.alive) return;
    lifeState = PlayerLifeState.dying;
    visual.playDeath();
    AudioService.instance.emit(GameAudioEvent.playerDied);
    if (gameSettings.hapticsEnabled) HapticFeedback.mediumImpact();
    _lifeStateTimer = 0.2;
    intents.hudAxis = 0;
    intents.keyboardAxis = 0;
    intents.consumeJump();
  }

  void activateCheckpoint(Vector2 checkpointPosition) {
    if (lifeState != PlayerLifeState.alive) return;
    checkpointSystem.activate(checkpointPosition, element);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (lifeState == PlayerLifeState.alive ||
        lifeState == PlayerLifeState.levelComplete) {
      return;
    }
    _lifeStateTimer -= dt;
    if (_lifeStateTimer > 0) return;

    if (lifeState == PlayerLifeState.dying) {
      lifeState = PlayerLifeState.respawning;
      _lifeStateTimer = 0.04;
      return;
    }

    final respawnPosition = checkpointSystem.respawnPosition;
    body
      ..x = respawnPosition.x
      ..y = respawnPosition.y
      ..vx = 0
      ..vy = 0
      ..grounded = false
      ..coyote = 0;
    position.setValues(respawnPosition.x, respawnPosition.y);
    stateMachine.reset(checkpointSystem.respawnElement);
    intents.activeElement = checkpointSystem.respawnElement;
    intents.activeElementListenable.value = checkpointSystem.respawnElement;
    visual.resetAfterRespawn(checkpointSystem.respawnElement);
    lifeState = PlayerLifeState.alive;
  }

  List<Rect> get solidAabbs => solids
      .where((block) => block.isSolid)
      .map((block) => block.toAbsoluteRect())
      .toList(growable: false);

  @override
  Future<void> onLoad() async {
    await add(PlayerInputComponent(intents));
    await add(PlayerPhysicsComponent());
    await add(visual);
    await add(RectangleHitbox());
  }
}
