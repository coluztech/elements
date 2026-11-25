enum ElementType {
  fire,
  water,
  earth,
  wood;

  static const coreColors = {
    ElementType.fire: 0xFFC0392B,
    ElementType.water: 0xFF1F6FB2,
    ElementType.earth: 0xFF8A5A32,
    ElementType.wood: 0xFF3D7A3D,
  };

  static const highlightColors = {
    ElementType.fire: 0xFFFF8A50,
    ElementType.water: 0xFF7FD1E8,
    ElementType.earth: 0xFFD9A15B,
    ElementType.wood: 0xFF8FD17A,
  };

  int get coreColor => coreColors[this]!;
  int get highlightColor => highlightColors[this]!;

  String get displayName => switch (this) {
    ElementType.fire => 'Fire',
    ElementType.water => 'Water',
    ElementType.earth => 'Earth',
    ElementType.wood => 'Wood',
  };

  String get iconName => switch (this) {
    ElementType.fire => '🔥',
    ElementType.water => '💧',
    ElementType.earth => '🪨',
    ElementType.wood => '🍃',
  };

  double get speedMultiplier => switch (this) {
    ElementType.fire => 1.1,
    ElementType.earth => 0.85,
    ElementType.water || ElementType.wood => 1.0,
  };

  double get jumpMultiplier => switch (this) {
    ElementType.earth => 1.08,
    _ => 1.0,
  };

  double get gravityMultiplier => switch (this) {
    ElementType.earth => 1.15,
    _ => 1.0,
  };
}
