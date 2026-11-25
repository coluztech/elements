import 'package:elements/game/components/hazards/element_hazard.dart';
import 'package:elements/game/systems/hazard_response_resolver.dart';
import 'package:flutter/material.dart';

class FireHazard extends ElementHazard {
  FireHazard({required super.position, required super.size})
    : super(
        hazardType: HazardType.fire,
        fill: const Color(0xFFC0392B),
      );
}
