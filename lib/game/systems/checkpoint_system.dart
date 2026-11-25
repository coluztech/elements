import 'package:elements/models/element_type.dart';
import 'package:flame/components.dart';

/// Stores the most recent safe position and form for the current attempt.
class CheckpointSystem {
  CheckpointSystem({
    required Vector2 playerStart,
    this.initialElement = ElementType.fire,
  }) : _position = playerStart.clone(),
       _element = initialElement;

  Vector2 _position;
  ElementType _element;
  final ElementType initialElement;

  Vector2 get respawnPosition => _position.clone();
  ElementType get respawnElement => _element;

  void activate(Vector2 position, ElementType element) {
    _position = position.clone();
    _element = element;
  }
}
