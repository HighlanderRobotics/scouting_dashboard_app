import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

class BreakdownMetrics {
  const BreakdownMetrics(this._values);

  final Map<String, Map<String, double>> _values;

  factory BreakdownMetrics.fromJson(Map<String, dynamic> json) {
    return BreakdownMetrics(
      json.map((breakdownPath, segments) => MapEntry(
            breakdownPath,
            (segments as Map<String, dynamic>).map(
              (segmentPath, value) =>
                  MapEntry(segmentPath, (value as num?)?.toDouble() ?? 0),
            ),
          )),
    );
  }

  Map<String, double>? breakdown(String path) => _values[path];

  double segmentValue(String breakdownPath, String segmentPath) =>
      _values[breakdownPath]?[segmentPath] ?? 0;

  bool isEmpty(String breakdownPath) =>
      _values[breakdownPath] == null || _values[breakdownPath]!.isEmpty;
}

extension GetBreakdownMetrics on LovatAPI {
  BreakdownMetrics? getCachedBreakdownMetricsByTeamNumber(int teamNumber) {
    return getCachedData(
      '/v1/analysis/breakdown/team/$teamNumber',
      parser: (json) =>
          BreakdownMetrics.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BreakdownMetrics> getBreakdownMetricsByTeamNumber(
    int teamNumber,
  ) async {
    final response = await get(
      '/v1/analysis/breakdown/team/$teamNumber',
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get breakdown metrics');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return BreakdownMetrics.fromJson(json);
  }
}