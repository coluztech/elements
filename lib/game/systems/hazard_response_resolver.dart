import 'package:elements/models/element_type.dart';

enum HazardType { fire, water, electric }

enum HazardOutcome {
  passThrough,
  extinguishesHazard,
  respawn,
  sinksThenRespawn,
  floats,
}

/// Centralizes all element-versus-hazard rules from SDD §22.3.
class HazardResponseResolver {
  HazardResponseResolver._();

  static HazardOutcome resolve(
    HazardType hazardType,
    ElementType element, {
    bool isLive = true,
  }) => switch (hazardType) {
    HazardType.fire => switch (element) {
      ElementType.fire => HazardOutcome.passThrough,
      ElementType.water => HazardOutcome.extinguishesHazard,
      ElementType.earth || ElementType.wood => HazardOutcome.respawn,
    },
    HazardType.water => switch (element) {
      ElementType.water => HazardOutcome.passThrough,
      ElementType.fire => HazardOutcome.respawn,
      ElementType.earth => HazardOutcome.sinksThenRespawn,
      ElementType.wood => HazardOutcome.floats,
    },
    HazardType.electric => element == ElementType.water && isLive
        ? HazardOutcome.respawn
        : HazardOutcome.passThrough,
  };
}
