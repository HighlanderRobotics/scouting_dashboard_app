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
      : num.toStringAsFixed(1).replaceAll(RegExp("\\.?0+\$"), "");
}

final List<MetricCategoryData> metricCategories = [
  MetricCategoryData("Score", [
    CategoryMetric(
      localizedName: "Total",
      abbreviatedLocalizedName: "Total",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "totalPoints",
    ),
    CategoryMetric(
      localizedName: "Auto",
      abbreviatedLocalizedName: "Auto",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "autoPoints",
    ),
    CategoryMetric(
      localizedName: "Teleop",
      abbreviatedLocalizedName: "Teleop",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "teleopPoints",
    ),
  ]),
  MetricCategoryData("Algae", [
    CategoryMetric(
      localizedName: "Processor scores",
      abbreviatedLocalizedName: "Processor",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "processorScores",
    ),
    CategoryMetric(
      localizedName: "Net scores",
      abbreviatedLocalizedName: "Net scores",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "netScores",
    ),
    CategoryMetric(
      localizedName: "Net fails",
      abbreviatedLocalizedName: "Net fails",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "netFails",
    ),
    CategoryMetric(
      localizedName: "Drops",
      abbreviatedLocalizedName: "Drops",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "algaeDrops",
    ),
    CategoryMetric(
      localizedName: "Feeds",
      abbreviatedLocalizedName: "Feeds",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "feeds",
    ),
  ]),
  MetricCategoryData("Coral", [
    CategoryMetric(
      localizedName: "Total coral",
      abbreviatedLocalizedName: "Total",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "totalCoral",
    ),
    CategoryMetric(
      localizedName: "L1 Score",
      abbreviatedLocalizedName: "L1",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "coralL1",
    ),
    CategoryMetric(
      localizedName: "L2 Score",
      abbreviatedLocalizedName: "L2",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "coralL2",
    ),
    CategoryMetric(
      localizedName: "L3 Score",
      abbreviatedLocalizedName: "L3",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "coralL3",
    ),
    CategoryMetric(
      localizedName: "L4 Score",
      abbreviatedLocalizedName: "L4",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "coralL4",
    ),
    CategoryMetric(
      localizedName: "Drops",
      abbreviatedLocalizedName: "Drops",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "coralDrops",
    ),
  ]),
  MetricCategoryData("Other", [
    CategoryMetric(
      localizedName: "Driver ability",
      abbreviatedLocalizedName: "Driver ability",
      valueVizualizationBuilder: ((rating) =>
          "${numberVizualizationBuilder(rating)}/5"),
      path: "driverAbility",
    ),
    CategoryMetric(
      localizedName: "Defends",
      abbreviatedLocalizedName: "Defends",
      valueVizualizationBuilder: ((p0) => numberVizualizationBuilder(p0)),
      path: "defends",
      hideDetails: true,
    ),
  ]),
];

List<BreakdownData> breakdowns = [
  BreakdownData(
    localizedName: "Role",
    path: "robotrole",
    segments: [
      BreakdownSegmentData(localizedNameSingular: "Offense", path: "OFFENSE"),
      BreakdownSegmentData(localizedNameSingular: "Defense", path: "DEFENSE"),
      BreakdownSegmentData(localizedNameSingular: "Feeder", path: "FEEDER"),
      BreakdownSegmentData(localizedNameSingular: "Immobile", path: "IMMOBILE"),
    ],
  ),
  BreakdownData(
    localizedName: "Coral intake",
    path: "coralpickup",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Ground",
        path: "NONE",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Ground",
        path: "GROUND",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Station",
        path: "STATION",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Both",
        path: "BOTH",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Algae intake",
    path: "algaepickup",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Ground",
        path: "NONE",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Ground",
        path: "GROUND",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Reef",
        path: "REEF",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Both",
        path: "BOTH",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Barge result",
    path: "bargeresult",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Not attempted",
        path: "NOT_ATTEMPTED",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Parked",
        path: "PARKED",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Shallow",
        path: "SHALLOW",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Shallow, failed",
        path: "FAILED_SHALLOW",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Deep",
        path: "DEEP",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Deep, failed",
        path: "FAILED_DEEP",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Knocks algae",
    path: "knocksalgae",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Yes",
        path: "True",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "No",
        path: "False",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Traverses under cage",
    path: "Undershallowcage",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Yes",
        path: "True",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "No",
        path: "False",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Leaves during auto",
    path: "leavesauto",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Yes",
        path: "True",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "No",
        path: "False",
      ),
    ],
  ),
];
