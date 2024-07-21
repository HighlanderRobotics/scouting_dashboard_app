import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension PrompoteAnalyst on LovatAPI {
  Future<void> promoteAnalyst(String id) async {
    final response = await post(
      '/v1/manager/upgradeuser',
      body: {
        'user': id,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to promote analyst');
    }
  }
}
