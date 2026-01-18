import 'package:flutter/material.dart';

enum RobotRoles {
  cycling,
  scoring,
  feeding,
  defending,
  immobile,
}

extension RobotRoleExtension on RobotRoles {
  String get name {
    switch (this) {
      case RobotRoles.cycling:
        return "Cycling";
      case RobotRoles.scoring:
        return "Scoring";
      case RobotRoles.feeding:
        return "Feeding";
      case RobotRoles.defending:
        return "Defending";
      case RobotRoles.immobile:
        return "Immobile";
    }
  }

  IconData get littleEmblem {
    switch (this) {
      case RobotRoles.cycling:
        return Icons.loop_rounded;
      case RobotRoles.defending:
        return Icons.shield_outlined;
      case RobotRoles.feeding:
        return Icons.conveyor_belt;
      case RobotRoles.scoring:
        return Icons.sports_score;
      case RobotRoles.immobile:
        return Icons.dangerous;
    }
  }
}
