import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension DeleteScoutReport on LovatAPI {
  Future<void> deleteScoutReport(String reportId) async {
    final response = await delete('/v1/manager/scoutreports/$reportId');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to delete scout report');
    }
  }
}
