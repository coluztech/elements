import 'package:elements/game/components/hazards/element_hazard.dart';
import 'package:elements/game/systems/hazard_response_resolver.dart';
import 'package:flutter/material.dart';

class WaterHazard extends ElementHazard {
  WaterHazard({required super.position, required super.size})
    : super(
        hazardType: HazardType.water,
        fill: const Color(0xFF1F6FB2),
      );
}
