import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension EditTeamEmail on LovatAPI {
  Future<void> editTeamEmail(String newEmail) async {
    final response = await lovatAPI.put(
      '/v1/manager/settings/teamemail',
      query: {
        'email': newEmail,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to edit team email');
      }
    }
  }
}
