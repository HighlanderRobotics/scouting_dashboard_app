import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/match.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';

class MetricDataPoint {
  const MetricDataPoint({
    required this.match,
    required this.tournamentName,
    this.dataPoint,
  });

  final GameMatchIdentity match;
  final String tournamentName;
  final double? dataPoint;

  factory MetricDataPoint.fromJson(Map<String, dynamic> json) {
    return MetricDataPoint(
      match: GameMatchIdentity.fromLongKey(
        json['match'] as String,
        tournamentName: json['tournamentName'] as String?,
      ),
      tournamentName: json['tournamentName'] as String? ?? '',
      dataPoint: (json['dataPoint'] as num?)?.toDouble(),
    );
  }
}

class MetricDetails {
  const MetricDetails({
    this.result,
    this.all,
    this.difference,
    this.team,
    this.array = const [],
    this.paths = const [],
    this.hasResult = false,
    this.hasAll = false,
    this.hasDifference = false,
  });

  final dynamic result;
  final dynamic all;
  final num? difference;
  final int? team;
  final List<MetricDataPoint> array;
  final List<AutoPath> paths;
  final bool hasResult;
  final bool hasAll;
  final bool hasDifference;

  factory MetricDetails.fromJson(Map<String, dynamic> json) {
    return MetricDetails(
      result: json['result'],
      all: json['all'],
      difference: json['difference'] as num?,
      team: json['team'] as int?,
      array: (json['array'] as List<dynamic>? ?? [])
          .map((e) => MetricDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      paths: (json['paths'] as List<dynamic>? ?? [])
          .map((e) => AutoPath.fromMap(e as Map<String, dynamic>))
          .toList(),
      hasResult: json.containsKey('result'),
      hasAll: json.containsKey('all'),
      hasDifference: json.containsKey('difference'),
    );
  }
}

extension MetricDetailsQuery on LovatAPI {
  CachedQuery<MetricDetails> metricDetailsQuery(
    int teamNumber,
    String metricPath,
  ) {
    final path = '/v1/analysis/metric/$metricPath/team/$teamNumber';
    return CachedQuery(
      queryKey: ['metricDetails', teamNumber, metricPath],
      label: 'metric details',
      queryFn: () async {
        final response = await get(path);

        if (response?.statusCode != 200) {
          debugPrint(response?.body ?? '');
          throw Exception('Failed to get metric details');
        }

        return MetricDetails.fromJson(
          jsonDecode(response!.body) as Map<String, dynamic>,
        );
      },
      cacheReader: () => getCachedData(
        path,
        parser: (json) => MetricDetails.fromJson(json as Map<String, dynamic>),
      ),
      cacheTimestampReader: () => getCachedTimestamp(path),
    );
  }
}
