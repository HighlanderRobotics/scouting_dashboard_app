import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';

class BreakdownMetrics {
  const BreakdownMetrics(this._values, {this.customFields = const []});

  final Map<String, Map<String, double>> _values;

  /// The viewing team's custom fields included inline in the response, whose
  /// values are the flat `cf_<uuid>` entries of the breakdown map.
  final List<CustomFieldBreakdownInfo> customFields;

  factory BreakdownMetrics.fromJson(Map<String, dynamic> json) {
    return BreakdownMetrics(
      Map.fromEntries(
        json.entries
            .where((entry) =>
                entry.key != 'customFields' &&
                entry.value is Map<String, dynamic>)
            .map((entry) => MapEntry(
                  entry.key,
                  (entry.value as Map<String, dynamic>).map(
                    (segmentPath, value) =>
                        MapEntry(segmentPath, (value as num?)?.toDouble() ?? 0),
                  ),
                )),
      ),
      customFields: CustomFieldBreakdownInfo.listFromJson(json['customFields']),
    );
  }

  Map<String, double>? breakdown(String path) => _values[path];

  double segmentValue(String breakdownPath, String segmentPath) =>
      _values[breakdownPath]?[segmentPath] ?? 0;

  bool isEmpty(String breakdownPath) =>
      _values[breakdownPath] == null || _values[breakdownPath]!.isEmpty;
}

/// Metadata about one of the viewing team's custom fields, included inline in
/// the breakdown metrics response as an entry of the `customFields` array
/// (`{uuid, metricKey, name, order, type, options}`).
class CustomFieldBreakdownInfo {
  const CustomFieldBreakdownInfo({
    required this.metricKey,
    required this.name,
    this.order = 0,
    this.options = const [],
  });

  final String metricKey;
  final String name;
  final int order;
  final List<String> options;

  /// Parses a single metadata entry, returning null for malformed entries.
  static CustomFieldBreakdownInfo? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;

    final metricKey = json['metricKey'];
    final name = json['name'];

    if (metricKey is! String || name is! String) return null;

    final order = json['order'];
    final options = json['options'];

    return CustomFieldBreakdownInfo(
      metricKey: metricKey,
      name: name,
      order: order is num ? order.toInt() : 0,
      options:
          options is List ? options.whereType<String>().toList() : const [],
    );
  }

  /// Parses the `customFields` metadata array from a breakdown metrics
  /// response, tolerating a missing or malformed array and skipping bad
  /// entries. Results are sorted by field order.
  static List<CustomFieldBreakdownInfo> listFromJson(dynamic json) {
    if (json is! List) return [];

    final fields =
        json.map(tryFromJson).whereType<CustomFieldBreakdownInfo>().toList();
    fields.sort((a, b) => a.order.compareTo(b.order));
    return fields;
  }
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
