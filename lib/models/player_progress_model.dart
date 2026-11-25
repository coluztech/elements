class LevelResult {
  const LevelResult({
    required this.stars,
    this.bestTimeMs,
    this.minSwaps,
    this.shardsCollected = 0,
    this.totalShards = 0,
    this.completed = true,
  });

  final int stars;
  final int? bestTimeMs;
  final int? minSwaps;
  final int shardsCollected;
  final int totalShards;
  final bool completed;
}

class PlayerProgressModel {
  const PlayerProgressModel({
    this.levelResults = const {},
    this.elementShardBalance = 0,
    this.ownedSkins = const {},
    this.equippedSkins = const {},
  });

  final Map<String, LevelResult> levelResults;
  final int elementShardBalance;
  final Set<String> ownedSkins;
  final Map<String, String> equippedSkins;

  int starsForWorld(int worldId) {
    final prefix = 'level_w${worldId}_';
    return levelResults.entries
        .where((entry) => entry.key.startsWith(prefix))
        .fold(0, (total, entry) => total + entry.value.stars);
  }

  bool isWorldUnlocked(int worldId) =>
      worldId == 1 || starsForWorld(worldId - 1) >= 30;

  bool isLevelUnlocked(int worldId, int levelIndex) {
    if (!isWorldUnlocked(worldId)) return false;
    if (levelIndex <= 1) return true;
    final previousId =
        'level_w${worldId}_${(levelIndex - 1).toString().padLeft(2, '0')}';
    return levelResults[previousId]?.completed ?? false;
  }
}
