import 'package:elements/models/player_progress_model.dart';

class ObjectiveSystem {
  ObjectiveSystem({required this.totalShards, required this.totalStars});

  final int totalShards;
  final int totalStars;
  int shardsCollected = 0;
  int starsCollected = 0;
  int swapCount = 0;
  int elapsedMs = 0;

  void update(double dt) {
    if (dt.isFinite && dt > 0) elapsedMs += (dt * 1000).round();
  }

  void collectShard() {
    if (shardsCollected < totalShards) shardsCollected++;
  }

  void collectStar() {
    if (starsCollected < totalStars) starsCollected++;
  }

  void recordSwap() => swapCount++;

  LevelResult complete() {
    return LevelResult(
      stars: starsCollected,
      bestTimeMs: elapsedMs,
      minSwaps: swapCount,
      shardsCollected: shardsCollected,
      totalShards: totalShards,
      completed: true,
    );
  }
}
