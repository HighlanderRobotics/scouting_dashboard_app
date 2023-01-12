import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';

class CategoryMetric {
  CategoryMetric({
    required this.localizedName,
    required this.abbreviatedLocalizedName,
    required this.valueVizualizationBuilder,
    required this.path,
  });

  String abbreviatedLocalizedName;
  String localizedName;

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

List<MetricCategoryData> metricCategories = [
  MetricCategoryData("Cargo", [
    CategoryMetric(
      localizedName: "Accuracy",
      abbreviatedLocalizedName: "Accuracy",
      valueVizualizationBuilder: (val) => "${((val as num) * 100).round()}%",
      path: "cargoAccuracy",
    ),
    CategoryMetric(
      localizedName: "Average count",
      abbreviatedLocalizedName: "Avg count",
      valueVizualizationBuilder: (val) => (val as num).round().toString(),
      path: "cargoCount",
    ),
  ]),
  MetricCategoryData("Climber", [
    CategoryMetric(
      localizedName: "Max climb",
      abbreviatedLocalizedName: "Maximum climb",
      valueVizualizationBuilder: (val) =>
          ClimbingChallenge.values[val as int].name,
      path: "climberMax",
    ),
  ]),
  MetricCategoryData("Defense", [
    CategoryMetric(
      localizedName: "Frequency",
      abbreviatedLocalizedName: "Frequency",
      valueVizualizationBuilder: (val) => "${val.round()}/5",
      path: "defenseQuantity",
    ),
    CategoryMetric(
      localizedName: "Success",
      abbreviatedLocalizedName: "Success",
      valueVizualizationBuilder: (val) => "${val.round()}/5",
      path: "defenseQuality",
    ),
  ]),
];
