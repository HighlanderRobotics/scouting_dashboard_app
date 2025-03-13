import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension SendTeamCode on LovatAPI {
  Future<String> sendTeamCode({required int teamNumber}) async {
    final response = await post(
      '/v1/manager/emailTeamCode',
      query: {
        "teamNumber": teamNumber.toString(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw const LovatAPIException('Failed to send team code');
    }

    return jsonDecode(response!.body)['email'];
  }
}
