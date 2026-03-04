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
    this.units,
  });

  String abbreviatedLocalizedName;
  String localizedName;
  bool hideDetails;
  bool hideOverview;
  bool hideFlag;
  double? max;
  String? units;
  String path;

  /// Optional override for completely custom formatting.
  /// If null, default formatting is used (number + units).
  String Function(dynamic)? valueToString;

  String get abbreviatedNameWithUnits {
    if (units == null || units!.trim().isEmpty) {
      return abbreviatedLocalizedName;
    }
    return "$abbreviatedLocalizedName (${units!.trim()})";
  }

  String valueVizualizationBuilder(dynamic val) {
    if (val == null) return "--";

    // If a custom formatter is provided, use it
    if (valueToString != null) {
      if (val is num) {
        return valueToString!(numToStringRounded(val));
      }
      return valueToString!(val);
    }

    // Default behavior: number + units (if present)
    if (val is num) {
      final value = numToStringRounded(val);
      return units != null ? "$value$units" : value;
    }

    return val.toString();
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
      units: " bps",
      path: "fuelPerSecond",
    ),
    CategoryMetric(
      localizedName: "Accuracy when shooting fuel",
      abbreviatedLocalizedName: "Accuracy",
      units: "%",
      max: 100,
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
      units: "s",
      path: "timeFeeding",
    ),
    CategoryMetric(
      localizedName: "Feeding Rate (Fuel / Second)",
      abbreviatedLocalizedName: "Feeding Rate",
      units: " bps",
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
      max: 5,
      units: "1-5",
      path: "driverAbility",
    ),
    CategoryMetric(
      localizedName: "Contact Defense Time",
      abbreviatedLocalizedName: "Contact Defense Time",
      units: "s",
      path: "contactDefenseTime",
    ),
    CategoryMetric(
      localizedName: "Defense effectiveness",
      abbreviatedLocalizedName: "Defense effectiveness",
      units: "1-5",
      max: 5,
      path: "defenseEffectiveness",
    ),
    CategoryMetric(
      localizedName: "Camping Defense Time",
      abbreviatedLocalizedName: "Camping Defense Time",
      units: "s",
      path: "campingDefenseTime",
    ),
    CategoryMetric(
      localizedName: "Total Defense Time (Camping + Contact)",
      abbreviatedLocalizedName: "Total Defense Time",
      units: "s",
      path: "totalDefenseTime",
    )
  ]),
  MetricCategoryData("Climb", [
    CategoryMetric(
      localizedName: "Seconds left when starting to climb L1",
      abbreviatedLocalizedName: "L1 Time",
      units: "s left",
      path: "l1StartTime",
    ),
    CategoryMetric(
      localizedName: "Seconds left when starting to climb L2",
      abbreviatedLocalizedName: "L2 Time",
      units: "s left",
      path: "l2StartTime",
    ),
    CategoryMetric(
      localizedName: "Seconds left when starting to climb L3",
      abbreviatedLocalizedName: "L3 Time",
      units: "s left",
      path: "l3StartTime",
    ),
    CategoryMetric(
      localizedName: "Seconds left in auto when starting to climb in auto",
      abbreviatedLocalizedName: "Auto Time",
      units: "s left",
      path: "autoClimbStartTime",
    ),
  ]),
  MetricCategoryData("Other", [
    CategoryMetric(
      localizedName: "Total fuel outputted between both feeding and scoring",
      abbreviatedLocalizedName: "Total Fuel Throughput",
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
          localizedNameSingular: "Defending", path: "DEFENDING"),
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
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Neither",
        path: "NEITHER",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Both",
        path: "BOTH",
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
      BreakdownSegmentData(
        localizedNameSingular: "Both",
        path: "BOTH",
      ),
      BreakdownSegmentData(
        localizedNameSingular: "Neither",
        path: "NEITHER",
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
