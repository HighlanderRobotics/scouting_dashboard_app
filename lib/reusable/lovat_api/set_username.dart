import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension SetUsername on LovatAPI {
  Future<void> setUsername(String username) async {
    final response = await post(
      '/v1/manager/onboarding/username',
      body: {
        'username': username,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to set username');
    }
  }
}
