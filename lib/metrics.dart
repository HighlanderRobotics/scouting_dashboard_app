import 'package:duration/duration.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';

class CategoryMetric {
  CategoryMetric({
    required this.localizedName,
    required this.abbreviatedLocalizedName,
    required this.valueVizualizationBuilder,
    required this.path,
    this.hideDetails = false,
    this.hideOverview = false,
    this.max,
  });

  String abbreviatedLocalizedName;
  String localizedName;
  bool hideDetails;
  bool hideOverview;
  double? max;

  String path;

  String Function(dynamic) valueVizualizationBuilder;
}

class MetricCategoryData {
  MetricCategoryData(
    this.localizedName,
    this.metrics,
  );

  String localizedName;
  List<CategoryMetric> metrics;
}

class BreakdownSegmentData {
  BreakdownSegmentData({
    required this.localizedNameSingular,
    this.localizedNamePlural,
    required this.path,
  });

  String localizedNameSingular;
  String? localizedNamePlural;

  String path;
}

class BreakdownData {
  BreakdownData({
    required this.localizedName,
    required this.path,
    required this.segments,
  });

  String localizedName;
  String path;
  List<BreakdownSegmentData> segments;
}

String numberVizualizationBuilder(num num) {
  return num.toStringAsFixed(2).replaceAll(RegExp("\\.?0+\$"), "");
}

final List<MetricCategoryData> metricCategories = [
  MetricCategoryData("Score", [
    CategoryMetric(
      localizedName: "Average total",
      abbreviatedLocalizedName: "Avg total",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "avgScore",
      hideDetails: true,
    ),
    CategoryMetric(
      localizedName: "Average auto",
      abbreviatedLocalizedName: "Avg auto",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "avgAutoScore",
    ),
    CategoryMetric(
      localizedName: "Average teleop",
      abbreviatedLocalizedName: "Avg teleop",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "avgTeleScore",
    ),
  ]),
  MetricCategoryData("Feed time", [
    CategoryMetric(
      localizedName: "Cones",
      abbreviatedLocalizedName: "Cones",
      valueVizualizationBuilder: ((p0) => prettyDuration(
          Duration(seconds: (p0 as num).toInt()),
          abbreviated: true)),
      path: "cycleConeTeam",
    ),
    CategoryMetric(
      localizedName: "Cubes",
      abbreviatedLocalizedName: "Cubes",
      valueVizualizationBuilder: ((p0) => prettyDuration(
          Duration(seconds: (p0 as num).toInt()),
          abbreviated: true)),
      path: "cycleCubeTeam",
    ),
  ]),
  MetricCategoryData("Autonomous", [
    CategoryMetric(
      localizedName: "Average cones",
      abbreviatedLocalizedName: "Avg cones",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "coneCountAuto",
    ),
    CategoryMetric(
      localizedName: "Average cubes",
      abbreviatedLocalizedName: "Avg cubes",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "cubeCountAuto",
    ),
    CategoryMetric(
      localizedName: "Paths",
      abbreviatedLocalizedName: "Paths",
      valueVizualizationBuilder: ((p0) => "Shouldn't show up"),
      path: "teamAutoPaths",
      hideOverview: true,
    ),
  ]),
  MetricCategoryData("Cones", [
    CategoryMetric(
      localizedName: "Average count",
      abbreviatedLocalizedName: "Avg count",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "coneCount",
    ),
    CategoryMetric(
      localizedName: "Cycle time",
      abbreviatedLocalizedName: "Cycle time",
      valueVizualizationBuilder: ((p0) => prettyDuration(
          Duration(seconds: (p0 as num).toInt()),
          abbreviated: true)),
      path: "cycleConeScore",
    ),
    CategoryMetric(
      localizedName: "Maximum row",
      abbreviatedLocalizedName: "Max row",
      valueVizualizationBuilder: ((p0) =>
          GridRow.values[(p0 as num).toInt()].localizedDescriptonAbbreviated),
      path: "coneMax",
      hideDetails: true,
    ),
  ]),
  MetricCategoryData("Cubes", [
    CategoryMetric(
      localizedName: "Average count",
      abbreviatedLocalizedName: "Avg count",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "cubeCount",
    ),
    CategoryMetric(
      localizedName: "Cycle time",
      abbreviatedLocalizedName: "Cycle time",
      valueVizualizationBuilder: ((p0) => prettyDuration(
          Duration(seconds: (p0 as num).toInt()),
          abbreviated: true)),
      path: "cycleCubeScore",
    ),
    CategoryMetric(
      localizedName: "Maximum row",
      abbreviatedLocalizedName: "Max row",
      valueVizualizationBuilder: ((p0) =>
          GridRow.values[(p0 as num).toInt()].localizedDescriptonAbbreviated),
      path: "cubeMax",
      hideDetails: true,
    ),
  ]),
  MetricCategoryData("Misc", [
    CategoryMetric(
      localizedName: "Avg defense time",
      abbreviatedLocalizedName: "Avg defense time",
      valueVizualizationBuilder: ((p0) => prettyDuration(
          Duration(seconds: (p0 as num).toInt()),
          abbreviated: true)),
      path: "defenseTime",
    ),
    CategoryMetric(
      localizedName: 'Driver ability',
      abbreviatedLocalizedName: 'Driver ability',
      valueVizualizationBuilder: (v) => numberVizualizationBuilder(v),
      path: 'driverAbility',
      max: 5,
    ),
    CategoryMetric(
      localizedName: 'Penalties',
      abbreviatedLocalizedName: 'Penalties',
      valueVizualizationBuilder: (val) => numberVizualizationBuilder(val),
      path: 'pentalties',
    ),
  ]),
  MetricCategoryData("Climber adjusted", [
    CategoryMetric(
      localizedName: "Docked",
      abbreviatedLocalizedName: "Docked",
      valueVizualizationBuilder: (p0) => numberVizualizationBuilder(p0),
      path: 'adjustedDocked',
      hideDetails: true,
    ),
    CategoryMetric(
      localizedName: "Engaged",
      abbreviatedLocalizedName: "Engaged",
      valueVizualizationBuilder: (p0) => numberVizualizationBuilder(p0),
      path: 'adjustedEngaged',
      hideDetails: true,
    ),
  ]),
];

List<BreakdownData> breakdowns = [
  BreakdownData(
    localizedName: "Role",
    path: "role",
    segments: [
      BreakdownSegmentData(localizedNameSingular: "Feeder", path: "feeder"),
      BreakdownSegmentData(localizedNameSingular: "Defense", path: "defense"),
      BreakdownSegmentData(localizedNameSingular: "Offense", path: "offense"),
      BreakdownSegmentData(localizedNameSingular: "Immobile", path: "immobile"),
    ],
  ),
  BreakdownData(
    localizedName: "Charge station teleop",
    path: "climber",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Dock",
        localizedNamePlural: "Docks",
        path: "docked",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Engage",
        localizedNamePlural: "engages",
        path: "engaged",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Fail",
        localizedNamePlural: "Fails",
        path: "failed",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Charge station auto",
    path: "climberAuto",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Dock",
        localizedNamePlural: "Docks",
        path: "docked",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Engage",
        localizedNamePlural: "Engages",
        path: "engaged",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Fail",
        localizedNamePlural: "Fails",
        path: "failed",
      ),
    ],
  ),
];
