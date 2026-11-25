import 'dart:convert';
import 'dart:io';

import 'package:elements/game/levels/level_schema_validator.dart';
import 'package:elements/models/world_model.dart';

void main() {
  final expectedIds = {
    for (final world in launchWorlds)
      for (var level = 1; level <= world.levelCount; level++)
        'level_w${world.id}_${level.toString().padLeft(2, '0')}',
  };
  final levelFiles =
      Directory('assets/levels')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final validator = LevelSchemaValidator();
  final errors = <String>[];
  final seenIds = <String>{};

  for (final file in levelFiles) {
    final filename = file.path.split(Platform.pathSeparator).last;
    final expectedId = filename.substring(0, filename.length - '.json'.length);
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      final level = validator.validateAndNormalize(decoded);
      final levelId = level['levelId'];
      if (levelId != expectedId) {
        errors.add('$filename: levelId must match "$expectedId".');
        continue;
      }
      if (!expectedIds.contains(levelId)) {
        errors.add('$filename: unexpected level id "$levelId".');
        continue;
      }
      final idParts = RegExp(r'^level_w(\d+)_(\d+)$').firstMatch(expectedId);
      final expectedWorld = int.parse(idParts!.group(1)!);
      final expectedIndex = int.parse(idParts.group(2)!);
      if (level['world'] != expectedWorld || level['index'] != expectedIndex) {
        errors.add(
          '$filename: world/index must be $expectedWorld/$expectedIndex.',
        );
        continue;
      }
      if (!seenIds.add(levelId! as String)) {
        errors.add('$filename: duplicate level id "$levelId".');
      }
    } on Object catch (error) {
      errors.add('$filename: $error');
    }
  }

  for (final missingId in expectedIds.difference(seenIds).toList()..sort()) {
    errors.add('Missing level file: $missingId.json.');
  }

  if (errors.isNotEmpty) {
    stderr.writeln('Level validation failed:');
    for (final error in errors) {
      stderr.writeln(' - $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Validated ${seenIds.length} levels: JSON and schema are valid.',
  );
}
