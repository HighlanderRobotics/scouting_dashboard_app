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
    'ranking',
    readableName: 'Tournament Ranking',
    description: 'Leaderboard rank from TBA',
    defaultHue: 220,
    visualizationBuilder: (context, data, foregroundColor, backgroundColor) =>
        FlagTemplate(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      child: Text(data.toString()),
    ),
  ),
  FlagType(
    'mainRole',
    readableName: 'Main Role',
    description: 'Robot\'s primary alliance role',
    defaultHue: 0,
    visualizationBuilder: (context, data, foregroundColor, backgroundColor) =>
        FlagTemplate(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      icon: RobotRole.values[data].littleEmblem,
    ),
  ),
  FlagType(
    'trend',
    readableName: "Score Trend",
    description: "Change in score over time",
    defaultHue: 256,
    visualizationBuilder: (context, data, foregroundColor, backgroundColor) =>
        FlagTemplate(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      icon: TeamTrend.values[data].icon,
    ),
  ),
  FlagType(
    'pentalties',
    readableName: "Penalties",
    description: 'Placeholder description',
    defaultHue: 30,
    disableHue: true,
    visualizationBuilder: (context, data, foregroundColor, backgroundColor) =>
        FlagFrame(
      foregroundColor: foregroundColor,
      backgroundColor: HSLColor.fromColor(Penalty.values[data].color)
          .withSaturation(0.4)
          .withLightness(0.7)
          .toColor(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 30,
            width: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: HSLColor.fromColor(Penalty.values[data].color)
                  .withSaturation(0.8)
                  .withLightness(0.2)
                  .toColor(),
            ),
          ),
        ],
      ),
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
