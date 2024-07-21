import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/raw_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetEventsForScoutReport on LovatAPI {
  Future<List<ScoutReportEvent>> getEventsForScoutReport(
    String reportId,
  ) async {
    final response = await get('/v1/analysis/timeline/scoutreport/$reportId');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get events for scout report');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json
        .map((e) => ScoutReportEvent.fromList((e as List<dynamic>).cast<int>()))
        .toList();
  }
}
