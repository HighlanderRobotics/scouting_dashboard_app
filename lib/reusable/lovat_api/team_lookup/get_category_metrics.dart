import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

class CategoryMetrics {
  const CategoryMetrics(this._values);

  final Map<String, dynamic> _values;

  factory CategoryMetrics.fromJson(Map<String, dynamic> json) {
    return CategoryMetrics(json);
  }

  dynamic valueForMetric(CategoryMetric metric) => _values[metric.path];
  dynamic valueForPath(String path) => _values[path];
}

extension GetCategoryMetrics on LovatAPI {
  CategoryMetrics? getCachedCategoryMetricsByTeamNumber(int teamNumber) {
    return getCachedData(
      '/v1/analysis/category/team/$teamNumber',
      parser: (json) =>
          CategoryMetrics.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<CategoryMetrics> getCategoryMetricsByTeamNumber(
    int teamNumber,
  ) async {
    final response = await get(
      '/v1/analysis/category/team/$teamNumber',
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get category metrics');
    }

    try {
      final json = jsonDecode(response!.body) as Map<String, dynamic>;

      return CategoryMetrics.fromJson(json);
    } on FormatException {
      if (["TEAM_DOES_NOT_EXIST", "NO_DATA_FOR_TEAM"]
          .contains(response!.body)) {
        throw LovatAPIException(response.body);
      } else {
        rethrow;
      }
    }
  }
}