import 'package:elements/models/element_type.dart';

class GridSize {
  const GridSize({
    required this.cols,
    required this.rows,
    required this.tileSize,
  });

  final int cols;
  final int rows;
  final int tileSize;
}

class LevelPoint {
  const LevelPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class LevelRect {
  const LevelRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

class LevelHazardData extends LevelRect {
  const LevelHazardData({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required this.type,
    this.isLive = true,
  });

  final String type;
  final bool isLive;
}

class LevelInteractableData extends LevelRect {
  const LevelInteractableData({
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required this.type,
    this.id,
    this.durationSeconds = 6,
  });

  final String type;
  final String? id;
  final double durationSeconds;
}

class LevelShard {
  const LevelShard({required this.x, required this.y});

  final double x;
  final double y;
}

class LevelStar {
  const LevelStar({required this.x, required this.y});

  final double x;
  final double y;
}

class LevelModel {
  const LevelModel({
    required this.levelId,
    required this.world,
    required this.index,
    required this.gridSize,
    required this.requiredElements,
    this.availableElements = ElementType.values,
    this.tutorialHint,
    required this.playerStart,
    required this.terrain,
    required this.hazards,
    this.interactables = const [],
    this.shards = const [],
    this.stars = const [],
    required this.checkpoints,
    required this.goal,
    this.parTimeMs,
    this.minSwapTarget,
  });

  final String levelId;
  final int world;
  final int index;
  final GridSize gridSize;
  final List<ElementType> requiredElements;
  final List<ElementType> availableElements;
  final String? tutorialHint;
  final int? parTimeMs;
  final int? minSwapTarget;
  final LevelPoint playerStart;
  final List<LevelRect> terrain;
  final List<LevelHazardData> hazards;
  final List<LevelInteractableData> interactables;
  final List<LevelShard> shards;
  final List<LevelStar> stars;
  final List<LevelPoint> checkpoints;
  final LevelRect goal;

  double get width => gridSize.cols * gridSize.tileSize.toDouble();
  double get height => gridSize.rows * gridSize.tileSize.toDouble();
}
