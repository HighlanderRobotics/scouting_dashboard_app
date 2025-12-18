import 'package:flutter/material.dart';

enum RobotRole {
  offense,
  defense,
  feeder,
  immobile,
}

extension RobotRoleExtension on RobotRole {
  String get name {
    switch (this) {
      case RobotRole.offense:
        return "Offense";
      case RobotRole.defense:
        return "Defense";
      case RobotRole.feeder:
        return "Feeder";
      case RobotRole.immobile:
        return "Immobile";
    }
  }

  IconData get littleEmblem {
    switch (this) {
      case RobotRole.offense:
        return Icons.sports_score;
      case RobotRole.defense:
        return Icons.shield_outlined;
      case RobotRole.feeder:
        return Icons.conveyor_belt;
      case RobotRole.immobile:
        return Icons.dangerous;
    }
  }
}
