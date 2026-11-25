import 'package:elements/models/player_progress_model.dart';
import 'package:elements/services/save_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final saveServiceProvider = Provider<SaveService>((ref) => appSaveService);

final progressProvider = FutureProvider<PlayerProgressModel>(
  (ref) => ref.watch(saveServiceProvider).getProgress(),
);
