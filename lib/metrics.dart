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
    this.hideFlag = false,
    this.max,
  });

  String abbreviatedLocalizedName;
  String localizedName;
  bool hideDetails;
  bool hideOverview;
  bool hideFlag;
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

String numberVizualizationBuilder(num? num) {
  return num == null
      ? "--"
      : num.toStringAsFixed(2).replaceAll(RegExp("\\.?0+\$"), "");
}

final List<MetricCategoryData> metricCategories = [
  MetricCategoryData("Score", [
    CategoryMetric(
      localizedName: "Average total",
      abbreviatedLocalizedName: "Avg total",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "totalpoints",
      hideDetails: true,
    ),
    CategoryMetric(
      localizedName: "Average auto",
      abbreviatedLocalizedName: "Avg auto",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "autopoints",
    ),
    CategoryMetric(
      localizedName: "Average teleop",
      abbreviatedLocalizedName: "Avg teleop",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "teleoppoints",
    ),
  ]),
  MetricCategoryData("Notes", [
    CategoryMetric(
      localizedName: "Amp scores",
      abbreviatedLocalizedName: "Amp",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "ampscores",
    ),
    CategoryMetric(
      localizedName: "Speaker scores",
      abbreviatedLocalizedName: "Speaker",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "speakerscores",
    ),
    CategoryMetric(
      localizedName: "Feeds",
      abbreviatedLocalizedName: "Feeds",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "feeds",
    ),
    CategoryMetric(
      localizedName: "Pickups",
      abbreviatedLocalizedName: "Pickups",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "pickups",
    ),
    CategoryMetric(
      localizedName: "Drops",
      abbreviatedLocalizedName: "Drops",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "drops",
    ),
  ]),
  MetricCategoryData("Other", [
    CategoryMetric(
      localizedName: "Driver ability",
      abbreviatedLocalizedName: "Driver ability",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "driverability",
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
