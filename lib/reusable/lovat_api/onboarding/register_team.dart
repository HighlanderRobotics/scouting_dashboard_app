import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension RegisterTeam on LovatAPI {
  Future<void> registerTeam(int teamNumber, String email) async {
    final response = await post(
      '/v1/manager/onboarding/team',
      body: {
        'email': email,
        'number': teamNumber,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to register team');
    }
  }
}
