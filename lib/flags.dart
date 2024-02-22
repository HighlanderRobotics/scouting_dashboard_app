import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';

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

final flags = <FlagType>[
  FlagType(
    'rank',
    readableName: 'Tournament Ranking',
    description: 'Leaderboard rank from TBA',
    defaultHue: 220,
    visualizationBuilder: (context, data, foregroundColor, backgroundColor) =>
        FlagTemplate(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      child: Text(data == 0 ? "N/A" : data.toString()),
    ),
  ),
  ...metricCategories
      .reduce((value, element) => MetricCategoryData(
            '',
            [...value.metrics, ...element.metrics],
          ))
      .metrics
      .where((e) => !e.hideOverview)
      .where((e) => !e.hideFlag)
      .map((e) => FlagType.categoryMetric(e)),
];

final defaultPicklistFlags = <FlagConfiguration>[
  FlagConfiguration.start(FlagType.byPath('ranking')),
];

final defaultTeamLookupFlag =
    FlagConfiguration.start(FlagType.byPath('ranking'));
