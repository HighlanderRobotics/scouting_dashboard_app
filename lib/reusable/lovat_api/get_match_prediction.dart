import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetMatchPrediction on LovatAPI {
  Future<Map<String, dynamic>> getMatchPrediction(
    int red1,
    int red2,
    int red3,
    int blue1,
    int blue2,
    int blue3,
  ) async {
    final response = await get(
      '/v1/analysis/matchprediction',
      query: {
        'red1': red1.toString(),
        'red2': red2.toString(),
        'red3': red3.toString(),
        'blue1': blue1.toString(),
        'blue2': blue2.toString(),
        'blue3': blue3.toString(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get match prediction');
    }

    if (response?.body == 'not enough data') {
      throw const LovatAPIException('Not enough data');
    }

    return jsonDecode(response!.body);
  }
}
