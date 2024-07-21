import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension DeleteAccount on LovatAPI {
  Future<void> deleteAccount() async {
    final response = await delete('/v1/manager/user');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to delete account');
    }
  }
}
