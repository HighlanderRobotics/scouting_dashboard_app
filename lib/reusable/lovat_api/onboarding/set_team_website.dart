import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension SetTeamWebsite on LovatAPI {
  Future<void> setTeamWebsite(String website) async {
    final response = await post(
      '/v1/manager/onboarding/teamwebsite',
      body: {
        'website': website,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to set team website');
    }
  }
}
