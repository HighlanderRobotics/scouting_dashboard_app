import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetMetricDetails on LovatAPI {
  Future<Map<String, dynamic>> getMetricDetails(
      int teamNumber, String metricPath) async {
    final response =
        await get('/v1/analysis/metric/$metricPath/team/$teamNumber');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get metric details');
    }

    return jsonDecode(response!.body);
  }
}
