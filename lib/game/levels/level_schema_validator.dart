import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Normalizes canonical level files and Tiled JSON exports to one runtime shape.
class LevelSchemaValidator {
  static const _elements = {'fire', 'water', 'earth', 'wood'};
  static const _hazards = {'fireHazard', 'waterHazard', 'electricHazard'};
  static const _interactables = {
    'fireSwitch',
    'waterSwitch',
    'earthSwitch',
    'universalSwitch',
    'crate',
    'woodAnchor',
    'earthAnchor',
    'burnableVine',
    'waterVolume',
  };

  Map<String, Object?> validateAndNormalize(Object? decoded) {
    if (decoded is! Map) {
      throw const FormatException('Level JSON root must be an object.');
    }
    final source = Map<String, Object?>.from(decoded);
    final canonical = source.containsKey('gridSize')
        ? source
        : TiledLevelAdapter.normalize(source);
    canonical.putIfAbsent('terrain', () => <Object?>[]);
    canonical.putIfAbsent('hazards', () => <Object?>[]);
    canonical.putIfAbsent('interactables', () => <Object?>[]);
    canonical.putIfAbsent('checkpoints', () => <Object?>[]);
    canonical.putIfAbsent('shards', () => <Object?>[]);
    canonical.putIfAbsent('stars', () => <Object?>[]);
    _validateCanonical(canonical);
    return canonical;
  }

  void _validateCanonical(Map<String, Object?> json) {
    final levelId = json['levelId'];
    if (levelId is! String || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(levelId)) {
      _fail(
        'levelId',
        'must be a non-empty identifier using letters, numbers, _ or -.',
      );
    }
    _positiveInt(json['world'], 'world');
    _positiveInt(json['index'], 'index');

    final grid = _object(json['gridSize'], 'gridSize');
    final cols = _positiveInt(grid['cols'], 'gridSize.cols');
    final rows = _positiveInt(grid['rows'], 'gridSize.rows');
    final tileSize = _positiveInt(grid['tileSize'], 'gridSize.tileSize');
    final mapWidth = (cols * tileSize).toDouble();
    final mapHeight = (rows * tileSize).toDouble();

    final requiredElements = json['requiredElements'];
    if (requiredElements is! List) {
      _fail('requiredElements', 'must be an array.');
    }
    for (var i = 0; i < requiredElements.length; i++) {
      if (requiredElements[i] is! String ||
          !_elements.contains(requiredElements[i])) {
        _fail('requiredElements[$i]', 'must be fire, water, earth, or wood.');
      }
    }
    final availableElements = json['availableElements'];
    if (availableElements != null) {
      if (availableElements is! List) {
        _fail('availableElements', 'must be an array.');
      }
      for (var i = 0; i < availableElements.length; i++) {
        if (availableElements[i] is! String ||
            !_elements.contains(availableElements[i])) {
          _fail(
            'availableElements[$i]',
            'must be fire, water, earth, or wood.',
          );
        }
      }
      if (!availableElements.toSet().containsAll(requiredElements)) {
        _fail('availableElements', 'must include every required element.');
      }
    }
    final tutorialHint = json['tutorialHint'];
    if (tutorialHint != null &&
        (tutorialHint is! String || tutorialHint.length > 180)) {
      _fail('tutorialHint', 'must be a string of at most 180 characters.');
    }

    _point(json['playerStart'], 'playerStart', mapWidth, mapHeight);

    final terrain = _list(json['terrain'] ?? const [], 'terrain');
    if (terrain.isEmpty) {
      _fail('terrain', 'must contain at least one solid rectangle.');
    }
    for (var i = 0; i < terrain.length; i++) {
      _rect(terrain[i], 'terrain[$i]', mapWidth, mapHeight);
    }

    final hazards = _list(json['hazards'] ?? const [], 'hazards');
    for (var i = 0; i < hazards.length; i++) {
      final hazard = _object(hazards[i], 'hazards[$i]');
      if (!_hazards.contains(hazard['type'])) {
        _fail(
          'hazards[$i].type',
          'must be fireHazard, waterHazard, or electricHazard.',
        );
      }
      if (hazard.containsKey('isLive') && hazard['isLive'] is! bool) {
        _fail('hazards[$i].isLive', 'must be a boolean.');
      }
      _rect(hazard, 'hazards[$i]', mapWidth, mapHeight);
    }

    final checkpoints = _list(json['checkpoints'] ?? const [], 'checkpoints');
    for (var i = 0; i < checkpoints.length; i++) {
      _point(checkpoints[i], 'checkpoints[$i]', mapWidth, mapHeight);
    }
    _rect(json['goal'], 'goal', mapWidth, mapHeight);
    final interactables = _list(
      json['interactables'] ?? const [],
      'interactables',
    );
    for (var i = 0; i < interactables.length; i++) {
      final item = _object(interactables[i], 'interactables[$i]');
      if (!_interactables.contains(item['type'])) {
        _fail('interactables[$i].type', 'unsupported interactable type.');
      }
      _rect(item, 'interactables[$i]', mapWidth, mapHeight);
      final duration = item['durationSeconds'];
      if (duration != null &&
          (duration is! num || !duration.isFinite || duration < 2)) {
        _fail(
          'interactables[$i].durationSeconds',
          'must be a finite number of at least 2 seconds.',
        );
      }
      if (item['id'] != null && item['id'] is! String) {
        _fail('interactables[$i].id', 'must be a string.');
      }
      if (item['crateOnly'] != null && item['crateOnly'] is! bool) {
        _fail('interactables[$i].crateOnly', 'must be a boolean.');
      }
    }
    final shards = _list(json['shards'] ?? const [], 'shards');
    for (var i = 0; i < shards.length; i++) {
      _point(shards[i], 'shards[$i]', mapWidth, mapHeight);
    }
    final stars = _list(json['stars'] ?? const [], 'stars');
    if (stars.length > 3) {
      _fail('stars', 'must contain at most 3 collectible stars.');
    }
    for (var i = 0; i < stars.length; i++) {
      _point(stars[i], 'stars[$i]', mapWidth, mapHeight);
    }
    _optionalPositiveInt(json['parTimeMs'], 'parTimeMs');
    _optionalPositiveInt(json['minSwapTarget'], 'minSwapTarget');
  }

  Map<String, Object?> _object(Object? value, String path) {
    if (value is! Map) _fail(path, 'must be an object.');
    return Map<String, Object?>.from(value);
  }

  List<Object?> _list(Object? value, String path) {
    if (value is! List) _fail(path, 'must be an array.');
    return List<Object?>.from(value);
  }

  int _positiveInt(Object? value, String path) {
    if (value is! int || value <= 0) _fail(path, 'must be a positive integer.');
    return value;
  }

  void _optionalPositiveInt(Object? value, String path) {
    if (value != null) _positiveInt(value, path);
  }

  void _point(Object? value, String path, double mapWidth, double mapHeight) {
    final point = _object(value, path);
    final x = _number(point['x'], '$path.x');
    final y = _number(point['y'], '$path.y');
    if (x < 0 || y < 0 || x >= mapWidth || y >= mapHeight) {
      _fail(path, 'must be inside the map bounds.');
    }
  }

  void _rect(Object? value, String path, double mapWidth, double mapHeight) {
    final rect = _object(value, path);
    final x = _number(rect['x'], '$path.x');
    final y = _number(rect['y'], '$path.y');
    final width = _number(rect['width'] ?? rect['w'], '$path.width');
    final height = _number(rect['height'] ?? rect['h'], '$path.height');
    if (width <= 0 || height <= 0) {
      _fail(path, 'width and height must be positive.');
    }
    if (x < 0 || y < 0 || x + width > mapWidth || y + height > mapHeight) {
      _fail(path, 'must fit inside the map bounds.');
    }
  }

  double _number(Object? value, String path) {
    if (value is! num || !value.isFinite) {
      _fail(path, 'must be a finite number.');
    }
    return value.toDouble();
  }

  Never _fail(String path, String message) =>
      throw FormatException('Invalid level JSON at $path: $message');
}

/// Converts Tiled's finite orthogonal JSON export into the runtime level schema.
class TiledLevelAdapter {
  TiledLevelAdapter._();

  static Map<String, Object?> normalize(Map<String, Object?> map) {
    if (map['orientation'] != null && map['orientation'] != 'orthogonal') {
      throw const FormatException(
        'Tiled maps must use orthogonal orientation.',
      );
    }
    if (map['infinite'] == true) {
      throw const FormatException('Infinite Tiled maps are not supported yet.');
    }
    final tileWidth = _int(map['tilewidth'], 'tilewidth');
    final tileHeight = _int(map['tileheight'], 'tileheight');
    if (tileWidth != tileHeight) {
      throw const FormatException('Tiled maps must use square tiles.');
    }
    final cols = _int(map['width'], 'width');
    final rows = _int(map['height'], 'height');
    final properties = _properties(map['properties']);
    final levelId = properties['levelId'] ?? map['name'];
    if (levelId is! String || levelId.isEmpty) {
      throw const FormatException(
        'Tiled map requires a levelId property or map name.',
      );
    }
    final idMatch = RegExp(r'^level_w(\d+)_(\d+)$').firstMatch(levelId);
    final world = _int(properties['world'] ?? idMatch?.group(1), 'world');
    final index = _int(properties['index'] ?? idMatch?.group(2), 'index');

    final requiredElements = _elements(properties['requiredElements']);
    final terrain = <Map<String, Object?>>[];
    final hazards = <Map<String, Object?>>[];
    final interactables = <Map<String, Object?>>[];
    final checkpoints = <Map<String, Object?>>[];
    Map<String, Object?>? playerStart;
    Map<String, Object?>? goal;
    final layers = map['layers'];
    if (layers is! List) {
      throw const FormatException('Tiled map layers must be an array.');
    }

    for (final rawLayer in layers) {
      if (rawLayer is! Map) continue;
      final layer = Map<String, Object?>.from(rawLayer);
      final layerName = (layer['name'] ?? '').toString().toLowerCase();
      final layerType = layer['type'];
      if (layerType == 'tilelayer' && _isCollisionLayer(layer, layerName)) {
        terrain.addAll(_terrainFromTileLayer(layer, tileWidth));
      } else if (layerType == 'objectgroup') {
        final objects = layer['objects'];
        if (objects is! List) continue;
        for (final rawObject in objects) {
          if (rawObject is! Map) continue;
          final object = Map<String, Object?>.from(rawObject);
          final objectProperties = _properties(object['properties']);
          final kind =
              (object['class'] ??
                      object['type'] ??
                      objectProperties['kind'] ??
                      '')
                  .toString();
          final rotation = object['rotation'];
          if (rotation is num && rotation != 0) {
            throw FormatException(
              'Rotated Tiled object ${object['id'] ?? ''} is unsupported.',
            );
          }
          final x = _numeric(object['x'], 'object.x');
          final y = _numeric(object['y'], 'object.y');
          final width = _numeric(object['width'] ?? 0, 'object.width');
          final height = _numeric(object['height'] ?? 0, 'object.height');
          final rect = <String, Object?>{
            'x': x,
            'y': y,
            'width': width,
            'height': height,
          };
          switch (kind.toLowerCase()) {
            case 'solid':
            case 'terrain':
              terrain.add(rect);
              break;
            case 'playerstart':
            case 'spawn':
              playerStart = {'x': x, 'y': y};
              break;
            case 'checkpoint':
              checkpoints.add({'x': x, 'y': y});
              break;
            case 'goal':
              goal = rect;
              break;
            case 'firehazard':
              hazards.add({
                ...rect,
                'type': 'fireHazard',
                if (objectProperties['isLive'] is bool)
                  'isLive': objectProperties['isLive'],
              });
              break;
            case 'waterhazard':
              hazards.add({
                ...rect,
                'type': 'waterHazard',
                if (objectProperties['isLive'] is bool)
                  'isLive': objectProperties['isLive'],
              });
              break;
            case 'electrichazard':
              hazards.add({
                ...rect,
                'type': 'electricHazard',
                if (objectProperties['isLive'] is bool)
                  'isLive': objectProperties['isLive'],
              });
              break;
            case 'fireswitch':
            case 'waterswitch':
            case 'earthswitch':
            case 'universalswitch':
            case 'crate':
            case 'woodanchor':
            case 'earthanchor':
            case 'burnablevine':
            case 'watervolume':
              interactables.add({
                ...rect,
                'type': switch (kind.toLowerCase()) {
                  'fireswitch' => 'fireSwitch',
                  'waterswitch' => 'waterSwitch',
                  'earthswitch' => 'earthSwitch',
                  'universalswitch' => 'universalSwitch',
                  'woodanchor' => 'woodAnchor',
                  'earthanchor' => 'earthAnchor',
                  'burnablevine' => 'burnableVine',
                  'watervolume' => 'waterVolume',
                  _ => 'crate',
                },
                if (object['id'] != null) 'id': object['id'].toString(),
                if (objectProperties['durationSeconds'] != null)
                  'durationSeconds': objectProperties['durationSeconds'],
                if (objectProperties['crateOnly'] is bool)
                  'crateOnly': objectProperties['crateOnly'],
              });
              break;
          }
        }
      }
    }

    playerStart ??= _propertyPoint(properties['playerStart']);
    goal ??= _propertyRect(properties['goal']);
    return {
      'levelId': levelId,
      'world': world,
      'index': index,
      'gridSize': {'cols': cols, 'rows': rows, 'tileSize': tileWidth},
      'requiredElements': requiredElements,
      'parTimeMs': properties['parTimeMs'],
      'minSwapTarget': properties['minSwapTarget'],
      'playerStart': playerStart,
      'checkpoints': checkpoints,
      'goal': goal,
      'terrain': terrain,
      'hazards': hazards,
      'interactables': interactables,
    };
  }

  static bool _isCollisionLayer(Map<String, Object?> layer, String name) {
    final properties = _properties(layer['properties']);
    return properties['collision'] == true ||
        name == 'terrain' ||
        name == 'collision' ||
        name == 'solid';
  }

  static List<Map<String, Object?>> _terrainFromTileLayer(
    Map<String, Object?> layer,
    int tileSize,
  ) {
    final data = _decodeTileData(layer);
    final width = _int(layer['width'], 'layer.width');
    final layerX = _numeric(layer['x'] ?? 0, 'layer.x').toInt();
    final layerY = _numeric(layer['y'] ?? 0, 'layer.y').toInt();
    if (data == null) return const [];
    final terrain = <Map<String, Object?>>[];
    for (var row = 0; row * width < data.length; row++) {
      var col = 0;
      while (col < width && row * width + col < data.length) {
        final gid = data[row * width + col];
        if (gid is! num || gid == 0) {
          col++;
          continue;
        }
        final start = col;
        while (col < width && row * width + col < data.length) {
          final nextGid = data[row * width + col];
          if (nextGid is! num || nextGid == 0) break;
          col++;
        }
        terrain.add({
          'x': (layerX + start) * tileSize,
          'y': (layerY + row) * tileSize,
          'width': (col - start) * tileSize,
          'height': tileSize,
        });
      }
    }
    return terrain;
  }

  static List<Object?>? _decodeTileData(Map<String, Object?> layer) {
    final rawData = layer['data'];
    if (rawData is List) return List<Object?>.from(rawData);
    if (rawData is! String || layer['encoding'] != 'base64') return null;

    final bytes = base64Decode(rawData);
    final compression = layer['compression'];
    final decodedBytes = switch (compression) {
      null || '' => bytes,
      'zlib' => ZLibDecoder().decodeBytes(bytes),
      'gzip' => GZipDecoder().decodeBytes(bytes),
      _ => throw FormatException(
        'Unsupported Tiled compression: $compression.',
      ),
    };
    if (decodedBytes.length % 4 != 0) {
      throw const FormatException(
        'Tiled tile data byte count must be divisible by 4.',
      );
    }
    final typedBytes = Uint8List.fromList(decodedBytes);
    final view = ByteData.sublistView(typedBytes);
    return List<Object?>.generate(
      decodedBytes.length ~/ 4,
      (index) => view.getUint32(index * 4, Endian.little),
      growable: false,
    );
  }

  static Map<String, Object?> _properties(Object? raw) {
    if (raw is Map) return Map<String, Object?>.from(raw);
    if (raw is! List) return {};
    final properties = <String, Object?>{};
    for (final entry in raw) {
      if (entry is Map && entry['name'] is String) {
        properties[entry['name'] as String] = entry['value'];
      }
    }
    return properties;
  }

  static List<String> _elements(Object? raw) {
    if (raw is List) return raw.map((value) => value.toString()).toList();
    if (raw is String) {
      return raw
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static Map<String, Object?>? _propertyPoint(Object? raw) {
    if (raw is Map) return Map<String, Object?>.from(raw);
    return null;
  }

  static Map<String, Object?>? _propertyRect(Object? raw) {
    if (raw is Map) return Map<String, Object?>.from(raw);
    return null;
  }

  static int _int(Object? value, String path) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    throw FormatException(
      'Invalid Tiled level JSON at $path: expected a positive integer.',
    );
  }

  static double _numeric(Object? value, String path) {
    if (value is num && value.isFinite) return value.toDouble();
    throw FormatException(
      'Invalid Tiled level JSON at $path: expected a finite number.',
    );
  }
}
