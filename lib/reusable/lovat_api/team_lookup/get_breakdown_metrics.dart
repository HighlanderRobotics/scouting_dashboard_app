import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetBreakdownMetrics on LovatAPI {
  Future<Map<String, dynamic>> getBreakdownMetricsByTeamNumber(
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

    return json;
  }
}
