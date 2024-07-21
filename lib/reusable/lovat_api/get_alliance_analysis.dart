import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetAllianceAnalysis on LovatAPI {
  Future<Map<String, dynamic>> getAllianceAnalysis(List<int> teams) async {
    final response = await get(
      '/v1/analysis/alliance',
      query: {
        'teamOne': teams[0].toString(),
        'teamTwo': teams[1].toString(),
        'teamThree': teams[2].toString(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get alliance analysis');
    }

    return jsonDecode(response!.body);
  }
}
