import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';

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
