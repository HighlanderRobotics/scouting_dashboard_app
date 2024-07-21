import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension SetNotOnTeam on LovatAPI {
  Future<void> setNotOnTeam() async {
    final response = await lovatAPI.post('/v1/manager/noteam');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to set not on team');
      }
    }
  }
}
