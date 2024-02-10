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
  MetricCategoryData("Note scoring", [
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
  ]),
  MetricCategoryData("Note interactions", [
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
      valueVizualizationBuilder: ((rating) => "$rating/5"),
      path: "driverability",
    ),
    CategoryMetric(
      localizedName: "Defense",
      abbreviatedLocalizedName: "Defense",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "defense",
      hideDetails: true,
    ),
  ]),
];

List<BreakdownData> breakdowns = [
  BreakdownData(
    localizedName: "Role",
    path: "robotRole",
    segments: [
      BreakdownSegmentData(localizedNameSingular: "Offense", path: "offense"),
      BreakdownSegmentData(localizedNameSingular: "Defense", path: "defense"),
      BreakdownSegmentData(localizedNameSingular: "Feeder", path: "feeder"),
      BreakdownSegmentData(localizedNameSingular: "Immobile", path: "immobile"),
    ],
  ),
  BreakdownData(
    localizedName: "Pick-up",
    path: "pickUp",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Ground",
        path: "ground",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Chute",
        path: "chute",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Both",
        path: "both",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "High note",
    path: "highNote",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Successful",
        path: "successful",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Fail",
        path: "failed",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Not attempted",
        path: "not_attempted",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Stage",
    path: "stage",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Nothing",
        path: "nothing",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Park",
        path: "park",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Onstage",
        path: "onstage",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Onstage & Harmony",
        path: "onstage_harmony",
      ),
    ],
  ),
];
