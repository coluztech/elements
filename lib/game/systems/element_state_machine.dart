import 'package:elements/models/element_type.dart';

enum ElementPlayerState { fire, water, earth, wood, swapping }

/// Owns element transitions and keeps the active form stable during a swap.
class ElementStateMachine {
  ElementStateMachine({
    required this.onTransformed,
    this.swapDuration = const Duration(milliseconds: 240),
    ElementType initialElement = ElementType.fire,
    this.availableElements,
  }) : currentElement = initialElement;

  final void Function(ElementType from, ElementType to) onTransformed;
  final Duration swapDuration;
  final Set<ElementType>? availableElements;

  ElementType currentElement;
  ElementType? _targetElement;
  ElementType? _bufferedElement;
  Duration _elapsed = Duration.zero;

  ElementType? get targetElement => _targetElement;
  bool get isSwapping => _targetElement != null;
  ElementPlayerState get state => isSwapping
      ? ElementPlayerState.swapping
      : switch (currentElement) {
          ElementType.fire => ElementPlayerState.fire,
          ElementType.water => ElementPlayerState.water,
          ElementType.earth => ElementPlayerState.earth,
          ElementType.wood => ElementPlayerState.wood,
        };
  double get swapProgress => isSwapping
      ? (_elapsed.inMicroseconds / swapDuration.inMicroseconds)
            .clamp(0.0, 1.0)
            .toDouble()
      : 1;

  /// Requests made during a transition keep the latest choice and run next.
  bool requestSwap(ElementType element) {
    if (availableElements != null && !availableElements!.contains(element)) {
      return false;
    }
    if (isSwapping) {
      _bufferedElement = element == _targetElement ? null : element;
      return false;
    }
    if (element == currentElement) return false;
    _targetElement = element;
    _elapsed = Duration.zero;
    return true;
  }

  /// Resets the form without emitting a transformation event (used on respawn).
  void reset(ElementType element) {
    currentElement = element;
    _targetElement = null;
    _bufferedElement = null;
    _elapsed = Duration.zero;
  }

  void update(double dt) {
    if (!isSwapping) return;
    const microsecondsPerSecond =
        Duration.millisecondsPerSecond * Duration.microsecondsPerMillisecond;
    _elapsed += Duration(microseconds: (dt * microsecondsPerSecond).round());
    if (_elapsed < swapDuration) return;

    final from = currentElement;
    currentElement = _targetElement!;
    _targetElement = null;
    _elapsed = Duration.zero;
    onTransformed(from, currentElement);

    final buffered = _bufferedElement;
    _bufferedElement = null;
    if (buffered != null && buffered != currentElement) requestSwap(buffered);
  }
}
