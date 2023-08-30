import 'package:flutter/material.dart';

enum TeamTrend {
  greatlyWorsening,
  slightlyWorsening,
  noChange,
  slightlyImproving,
  greatlyImproving,
}

extension TeamTrendExtension on TeamTrend {
  String get localizedDescription {
    switch (this) {
      case TeamTrend.greatlyWorsening:
        return "Greatly worsening";
      case TeamTrend.slightlyWorsening:
        return "Slightly worsening";
      case TeamTrend.noChange:
        return "No change";
      case TeamTrend.slightlyImproving:
        return "Slightly improving";
      case TeamTrend.greatlyImproving:
        return "Greatly improving";
    }
  }

  IconData get icon {
    switch (this) {
      case TeamTrend.greatlyWorsening:
        return Icons.south;
      case TeamTrend.slightlyWorsening:
        return Icons.south_east;
      case TeamTrend.noChange:
        return Icons.east;
      case TeamTrend.slightlyImproving:
        return Icons.north_east;
      case TeamTrend.greatlyImproving:
        return Icons.north;
    }
  }
}
