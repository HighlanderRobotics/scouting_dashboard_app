import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';

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

extension BreakdownMetricsQuery on LovatAPI {
  CachedQuery<BreakdownMetrics> breakdownMetricsQuery(int teamNumber) {
    final path = '/v1/analysis/breakdown/team/$teamNumber';
    return CachedQuery(
      queryKey: ['breakdownMetrics', teamNumber],
      label: 'breakdown metrics',
      queryFn: () async {
        final response = await get(path);

        if (response?.statusCode != 200) {
          debugPrint(response?.body ?? '');
          throw Exception('Failed to get breakdown metrics');
        }

        final json = jsonDecode(response!.body) as Map<String, dynamic>;

        return BreakdownMetrics.fromJson(json);
      },
      cacheReader: () => getCachedData(
        path,
        parser: (json) =>
            BreakdownMetrics.fromJson(json as Map<String, dynamic>),
      ),
      cacheTimestampReader: () => getCachedTimestamp(path),
    );
  }
}
