import 'dart:convert';

import 'package:elements/game/levels/level_schema_validator.dart';
import 'package:elements/models/element_type.dart';
import 'package:elements/models/level_model.dart';
import 'package:flutter/services.dart';

class LevelLoader {
  LevelLoader({AssetBundle? bundle, LevelSchemaValidator? validator})
    : _bundle = bundle ?? rootBundle,
      _validator = validator ?? LevelSchemaValidator();

  final AssetBundle _bundle;
  final LevelSchemaValidator _validator;

  Future<LevelModel> load(String levelId) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(levelId)) {
      throw ArgumentError.value(
        levelId,
        'levelId',
        'Invalid level identifier.',
      );
    }
    final assetPath = 'assets/levels/$levelId.json';
    final String source;
    try {
      source = await _bundle.loadString(assetPath);
    } catch (error) {
      throw FormatException('Could not load $assetPath: $error');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Malformed JSON in $assetPath: ${error.message}');
    }
    final json = _validator.validateAndNormalize(decoded);
    if (json['levelId'] != levelId) {
      throw FormatException(
        'Level id mismatch in $assetPath: expected "$levelId", '
        'found "${json['levelId']}".',
      );
    }
    return _toModel(json);
  }

  LevelModel _toModel(Map<String, Object?> json) {
    final grid = Map<String, Object?>.from(json['gridSize']! as Map);
    final playerStart = Map<String, Object?>.from(json['playerStart']! as Map);
    final goal = _rect(json['goal']!);
    final terrain = (json['terrain']! as List)
        .map(_rect)
        .toList(growable: false);
    final hazards = (json['hazards']! as List)
        .map((rawHazard) {
          final hazard = Map<String, Object?>.from(rawHazard as Map);
          final rect = _rect(hazard);
          return LevelHazardData(
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
            type: hazard['type']! as String,
            isLive: hazard['isLive'] as bool? ?? true,
          );
        })
        .toList(growable: false);
    final interactables = (json['interactables']! as List)
        .map((rawItem) {
          final item = Map<String, Object?>.from(rawItem as Map);
          final rect = _rect(item);
          return LevelInteractableData(
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
            type: item['type']! as String,
            id: item['id'] as String?,
            durationSeconds: (item['durationSeconds'] as num?)?.toDouble() ?? 6,
          );
        })
        .toList(growable: false);
    final checkpoints = (json['checkpoints']! as List)
        .map((rawPoint) {
          final point = Map<String, Object?>.from(rawPoint as Map);
          return LevelPoint(
            x: (point['x']! as num).toDouble(),
            y: (point['y']! as num).toDouble(),
          );
        })
        .toList(growable: false);

    return LevelModel(
      levelId: json['levelId']! as String,
      world: json['world']! as int,
      index: json['index']! as int,
      gridSize: GridSize(
        cols: grid['cols']! as int,
        rows: grid['rows']! as int,
        tileSize: grid['tileSize']! as int,
      ),
      requiredElements: (json['requiredElements']! as List)
          .map((element) => ElementType.values.byName(element as String))
          .toList(growable: false),
      availableElements:
          (json['availableElements'] as List? ??
                  json['requiredElements']! as List)
              .map((element) => ElementType.values.byName(element as String))
              .toList(growable: false),
      tutorialHint: json['tutorialHint'] as String?,
      parTimeMs: json['parTimeMs'] as int?,
      minSwapTarget: json['minSwapTarget'] as int?,
      playerStart: LevelPoint(
        x: (playerStart['x']! as num).toDouble(),
        y: (playerStart['y']! as num).toDouble(),
      ),
      terrain: terrain,
      hazards: hazards,
      interactables: interactables,
      shards: (json['shards']! as List)
          .map((rawShard) {
            final shard = Map<String, Object?>.from(rawShard as Map);
            return LevelShard(
              x: (shard['x']! as num).toDouble(),
              y: (shard['y']! as num).toDouble(),
            );
          })
          .toList(growable: false),
      stars: (json['stars']! as List)
          .map((rawStar) {
            final star = Map<String, Object?>.from(rawStar as Map);
            return LevelStar(
              x: (star['x']! as num).toDouble(),
              y: (star['y']! as num).toDouble(),
            );
          })
          .toList(growable: false),
      checkpoints: checkpoints,
      goal: goal,
    );
  }

  LevelRect _rect(Object? raw) {
    final rect = Map<String, Object?>.from(raw as Map);
    return LevelRect(
      x: (rect['x']! as num).toDouble(),
      y: (rect['y']! as num).toDouble(),
      width: ((rect['width'] ?? rect['w'])! as num).toDouble(),
      height: ((rect['height'] ?? rect['h'])! as num).toDouble(),
    );
  }
}
