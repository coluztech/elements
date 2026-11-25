import 'package:elements/game/components/hazards/element_hazard.dart';
import 'package:elements/game/systems/hazard_response_resolver.dart';
import 'package:flutter/material.dart';

class ElectricHazard extends ElementHazard {
  ElectricHazard({
    required super.position,
    required super.size,
    super.isLive = true,
  }) : super(
         hazardType: HazardType.electric,
         fill: const Color(0xFFE3C641),
       );
}
