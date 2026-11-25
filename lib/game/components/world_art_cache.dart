import 'dart:ui' as ui;

import 'package:flame/flame.dart';

/// Shared non-blocking image cache for level props and terrain.
class WorldArtCache {
  WorldArtCache._();

  static final Map<String, ui.Image> _images = {};
  static final Map<String, Future<void>> _pending = {};

  static ui.Image? image(String asset) => _images[asset];

  static Future<void> preload(String asset) =>
      _pending.putIfAbsent(asset, () async {
        final image = await Flame.images.load(asset);
        _images[asset] = image;
      });
}
