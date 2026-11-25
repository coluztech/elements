import 'package:elements/models/player_progress_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Flutter-layer persistence facade. Game components never access Hive directly.
class SaveService {
  static const _boxName = 'progress';
  static const _schemaVersion = 2;
  static const _skinElements = <String, String>{
    'fire_ember': 'fire',
    'water_glacier': 'water',
    'earth_copper': 'earth',
    'wood_jade': 'wood',
  };

  Box<dynamic>? _box;
  Future<void>? _initializing;

  Future<void> init() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    final versionValue = _box!.get('schemaVersion', defaultValue: 0);
    final storedVersion = versionValue is int ? versionValue : 0;
    if (storedVersion == 1) {
      final rawResults = _box!.get('levelResults');
      if (rawResults is Map) {
        final migrated = <String, dynamic>{};
        for (final entry in rawResults.entries) {
          if (entry.key is! String || entry.value is! Map) continue;
          final result = Map<String, dynamic>.from(entry.value as Map)
            ..['stars'] = 0;
          migrated[entry.key as String] = result;
        }
        await _box!.put('levelResults', migrated);
      }
    }
    if (storedVersion < _schemaVersion) {
      await _box!.put('schemaVersion', _schemaVersion);
    }
  }

  Future<PlayerProgressModel> getProgress() async {
    await init();
    final rawResults = _box!.get(
      'levelResults',
      defaultValue: <String, dynamic>{},
    );
    final resultsMap = rawResults is Map
        ? Map<String, dynamic>.from(rawResults)
        : <String, dynamic>{};
    final results = <String, LevelResult>{};
    for (final entry in resultsMap.entries) {
      if (entry.value is! Map) continue;
      final data = Map<String, dynamic>.from(entry.value as Map);
      results[entry.key] = LevelResult(
        stars: data['stars'] as int? ?? 0,
        bestTimeMs: data['bestTimeMs'] as int?,
        minSwaps: data['minSwaps'] as int?,
        shardsCollected: data['shardsCollected'] as int? ?? 0,
        totalShards: data['totalShards'] as int? ?? 0,
        completed: data['completed'] as bool? ?? true,
      );
    }
    final rawEquipped = _box!.get(
      'equippedSkins',
      defaultValue: <String, String>{},
    );
    return PlayerProgressModel(
      levelResults: results,
      elementShardBalance:
          _box!.get('elementShardBalance', defaultValue: 0) as int,
      ownedSkins: Set<String>.from(
        (_box!.get('ownedSkins', defaultValue: <String>[]) as List)
            .cast<String>(),
      ),
      equippedSkins: rawEquipped is Map
          ? Map<String, String>.from(rawEquipped)
          : const {},
    );
  }

  Future<PlayerProgressModel> purchaseSkin({
    required String skinId,
    required int price,
  }) async {
    await init();
    final progress = await getProgress();
    if (price <= 0) throw ArgumentError.value(price, 'price');
    if (progress.ownedSkins.contains(skinId)) return equipSkin(skinId);
    if (progress.elementShardBalance < price) {
      throw StateError('Not enough Element Shards.');
    }
    final element = _elementForSkin(skinId);
    final owned = {...progress.ownedSkins, skinId};
    final equipped = {...progress.equippedSkins, element: skinId};
    await _box!.put(
      'elementShardBalance',
      progress.elementShardBalance - price,
    );
    await _box!.put('ownedSkins', owned.toList());
    await _box!.put('equippedSkins', equipped);
    return getProgress();
  }

  Future<PlayerProgressModel> equipSkin(String skinId) async {
    await init();
    final progress = await getProgress();
    if (!progress.ownedSkins.contains(skinId)) {
      throw StateError('Purchase this cosmetic before equipping it.');
    }
    final equipped = {
      ...progress.equippedSkins,
      _elementForSkin(skinId): skinId,
    };
    await _box!.put('equippedSkins', equipped);
    return getProgress();
  }

  String _elementForSkin(String skinId) {
    final element = _skinElements[skinId];
    if (element == null) {
      throw ArgumentError.value(skinId, 'skinId', 'Unknown cosmetic skin.');
    }
    return element;
  }

  Future<PlayerProgressModel> recordLevelResult(
    String levelId,
    LevelResult result,
  ) async {
    final progress = await getProgress();
    final previous = progress.levelResults[levelId];
    final merged = LevelResult(
      stars: _max(previous?.stars ?? 0, result.stars),
      bestTimeMs: _minNullable(previous?.bestTimeMs, result.bestTimeMs),
      minSwaps: _minNullable(previous?.minSwaps, result.minSwaps),
      shardsCollected: _max(
        previous?.shardsCollected ?? 0,
        result.shardsCollected,
      ),
      totalShards: _max(previous?.totalShards ?? 0, result.totalShards),
      completed: true,
    );
    final results = Map<String, LevelResult>.from(progress.levelResults)
      ..[levelId] = merged;
    final rawResults = <String, dynamic>{
      for (final entry in results.entries)
        entry.key: <String, dynamic>{
          'stars': entry.value.stars,
          'bestTimeMs': entry.value.bestTimeMs,
          'minSwaps': entry.value.minSwaps,
          'shardsCollected': entry.value.shardsCollected,
          'totalShards': entry.value.totalShards,
          'completed': entry.value.completed,
        },
    };
    final newlyEarnedShards =
        _max(previous?.shardsCollected ?? 0, result.shardsCollected) -
        (previous?.shardsCollected ?? 0);
    await _box!.put('levelResults', rawResults);
    await _box!.put(
      'elementShardBalance',
      progress.elementShardBalance + newlyEarnedShards,
    );
    return getProgress();
  }

  int _max(int first, int second) => first > second ? first : second;

  int? _minNullable(int? first, int? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first < second ? first : second;
  }
}

final appSaveService = SaveService();
