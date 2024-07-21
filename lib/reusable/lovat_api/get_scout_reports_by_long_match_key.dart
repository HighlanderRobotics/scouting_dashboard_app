import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetScoutReportsByLongMatchKey on LovatAPI {
  Future<List<MinimalScoutReportInfo>> getScoutReportsByLongMatchKey(
    String longMatchKey,
  ) async {
    final response = await get('/v1/analysis/scoutreports/match/$longMatchKey');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get scout reports');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => MinimalScoutReportInfo.fromJson(e)).toList();
  }
}
