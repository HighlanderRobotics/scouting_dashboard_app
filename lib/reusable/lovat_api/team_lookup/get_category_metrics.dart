import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetCategoryMetrics on LovatAPI {
  Future<Map<String, dynamic>> getCategoryMetricsByTeamNumber(
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

      return json;
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
