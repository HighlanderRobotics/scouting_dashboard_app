import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';

class CategoryMetric {
  CategoryMetric({
    required this.localizedName,
    required this.abbreviatedLocalizedName,
    required this.valueVizualizationBuilder,
    required this.path,
    this.hideDetails = false,
    this.hideOverview = false,
  });

  String abbreviatedLocalizedName;
  String localizedName;
  bool hideDetails;
  bool hideOverview;

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

List<MetricCategoryData> metricCategories = [];

List<BreakdownData> breakdowns = [];
