class WorldModel {
  const WorldModel({
    required this.id,
    required this.name,
    required this.levelCount,
  });

  final int id;
  final String name;
  final int levelCount;
}

const launchWorlds = [
  WorldModel(id: 1, name: 'Foundations', levelCount: 15),
  WorldModel(id: 2, name: 'Convergence', levelCount: 15),
  WorldModel(id: 3, name: 'Momentum', levelCount: 15),
  WorldModel(id: 4, name: 'Mastery', levelCount: 15),
];
