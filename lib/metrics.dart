import 'dart:math';

class CategoryMetric {
  CategoryMetric({
    required this.localizedName,
    required this.abbreviatedLocalizedName,
    this.valueToString,
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

  String Function(dynamic)? valueToString;

  String valueVizualizationBuilder(dynamic val) {
    if (valueToString != null) {
      if (val is num) {
        return valueToString!(numToStringRounded(val));
      } else {
        return valueToString!(val);
      }
    }

    if (val is num) {
      return numToStringRounded(val);
    }

    return "--";
  }
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

String numToStringRounded(num? num) {
  return num == null
      ? "--"
      : num.toStringAsFixed(1).replaceAll(RegExp("\\.?0+\$"), "");
}

final List<MetricCategoryData> metricCategories = [
  MetricCategoryData("Score", [
    CategoryMetric(
      localizedName: "Total",
      abbreviatedLocalizedName: "Total",
      path: "totalPoints",
    ),
    CategoryMetric(
      localizedName: "Auto",
      abbreviatedLocalizedName: "Auto",
      path: "autoPoints",
    ),
    CategoryMetric(
      localizedName: "Teleop",
      abbreviatedLocalizedName: "Teleop",
      path: "teleopPoints",
    ),
  ]),
  MetricCategoryData("Hub", [
    CategoryMetric(
      localizedName: "Scoring Rate (Fuel / Second)",
      abbreviatedLocalizedName: "Scoring Rate",
      valueToString: ((p0) => "$p0 bps"),
      path: "fuelPerSecond",
    ),
    CategoryMetric(
      localizedName: "Accuracy when shooting fuel",
      abbreviatedLocalizedName: "Accuracy",
      valueToString: ((p0) => "$p0%"),
      path: "accuracy",
    ),
    CategoryMetric(
      localizedName: "Volleys per match",
      abbreviatedLocalizedName: "Volleys/Match",
      path: "volleysPerMatch",
    )
  ]),
  MetricCategoryData("Feeding", [
    CategoryMetric(
      localizedName: "Time Spent Feeding",
      abbreviatedLocalizedName: "Time Feeding",
      valueToString: ((p0) => "${p0}s"),
      path: "timeFeeding",
    ),
    CategoryMetric(
      localizedName: "Feeding Rate (Fuel / Second)",
      abbreviatedLocalizedName: "Feeding Rate",
      valueToString: ((p0) => "$p0 bps"),
      path: "feedingRate",
    ),
    CategoryMetric(
      localizedName: "Feeds per match",
      abbreviatedLocalizedName: "Feeds/Match",
      path: "feedsPerMatch",
    )
  ]),
  MetricCategoryData("Driving & Defense", [
    CategoryMetric(
      localizedName: "Driver Ability",
      abbreviatedLocalizedName: "Driver Ability",
      valueToString: ((p0) => "$p0/5"),
      max: 5,
      path: "driverAbility",
    ),
    CategoryMetric(
      localizedName: "Contact Defense Time",
      abbreviatedLocalizedName: "Contact Defense Time",
      valueToString: ((p0) => "${p0}s"),
      path: "contactDefenseTime",
    ),
    CategoryMetric(
      localizedName: "Defense effectiveness",
      abbreviatedLocalizedName: "Defense effectiveness",
      valueToString: ((p0) => "$p0/5"),
      path: "defenseEffectiveness",
    ),
    CategoryMetric(
      localizedName: "Camping Defense Time",
      abbreviatedLocalizedName: "Camping Defense Time",
      valueToString: ((p0) => "${p0}s"),
      path: "campingDefenseTime",
    ),
    CategoryMetric(
      localizedName: "Total Defense Time (Camping + Contact)",
      abbreviatedLocalizedName: "Total Defense Time",
      valueToString: ((p0) => "${p0}s"),
      path: "totalDefenseTime",
    )
  ]),
  MetricCategoryData("Climb", [
    CategoryMetric(
      localizedName: "Seconds left when starting to climb L1",
      abbreviatedLocalizedName: "L1 Time",
      valueToString: ((p0) => "${p0}s left"),
      path: "l1StartTime",
    ),
    CategoryMetric(
      localizedName: "Seconds left when starting to climb L2",
      abbreviatedLocalizedName: "L2 Time",
      valueToString: ((p0) => "${p0}s left"),
      path: "l2StartTime",
    ),
    CategoryMetric(
      localizedName: "Seconds left when starting to climb L3",
      abbreviatedLocalizedName: "L3 Time",
      valueToString: ((p0) => "${p0}s left"),
      path: "l3StartTime",
    ),
    CategoryMetric(
      localizedName: "Seconds left in auto when starting to climb in auto",
      abbreviatedLocalizedName: "Auto Time",
      valueToString: ((p0) => "${p0}s left"),
      path: "autoClimbStartTime",
    ),
  ]),
  MetricCategoryData("Other", [
    CategoryMetric(
      localizedName: "Total fuel outputted between both feeding and scoring",
      abbreviatedLocalizedName: "Fuel Outputted",
      path: "totalFuelOutputted",
    ),
    CategoryMetric(
      localizedName: "Outpost Intakes",
      abbreviatedLocalizedName: "Outpost Intakes",
      path: "outpostIntakes",
    )
  ])
];

List<BreakdownData> breakdowns = [
  BreakdownData(
    localizedName: "Roles",
    path: "robotRole",
    segments: [
      BreakdownSegmentData(localizedNameSingular: "Cycling", path: "CYCLING"),
      BreakdownSegmentData(localizedNameSingular: "Scoring", path: "SCORING"),
      BreakdownSegmentData(localizedNameSingular: "Feeding", path: "FEEDING"),
      BreakdownSegmentData(
          localizedNameSingular: "Defending", path: "Defending"),
      BreakdownSegmentData(localizedNameSingular: "Immobile", path: "IMMOBILE"),
    ],
  ),
  BreakdownData(
    localizedName: "Traversal",
    path: "fieldTraversal",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "None",
        path: "NONE",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Trench",
        path: "TRENCH",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Bump",
        path: "BUMP",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Both",
        path: "BOTH",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Climb Result",
    path: "climbResult",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Not Attempted",
        path: "NOT_ATTEMPTED",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Failed",
        path: "FAILED",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "L1",
        path: "L1",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "L2",
        path: "L2",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "L3",
        path: "L3",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Beaching",
    path: "beached",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "On Fuel",
        path: "ON_FUEL",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "On Bump",
        path: "ON_BUMP",
      )
    ],
  ),
  BreakdownData(
    localizedName: "Scores While Moving",
    path: "scoresWhileMoving",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Yes",
        path: "TRUE",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "No",
        path: "FALSE",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Intake Type",
    path: "intakeType",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Ground",
        path: "GROUND",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Outpost",
        path: "OUTPOST",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Disrupts Fuel in Auto",
    path: "disrupts",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Yes",
        path: "TRUE",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "No",
        path: "FALSE",
      ),
    ],
  ),
  BreakdownData(
    localizedName: "Feeder Type",
    path: "feederType",
    segments: [
      BreakdownSegmentData(
        localizedNameSingular: "Continuous",
        path: "CONTINUOUS",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Stop to Shoot",
        path: "STOP_TO_SHOOT",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Dump",
        path: "DUMP",
      ),
    ],
  )
];
