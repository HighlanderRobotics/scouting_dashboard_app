import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension DeleteSharedPicklist on LovatAPI {
  Future<void> deleteSharedPicklist(String id) async {
    final response = await delete('/v1/manager/picklists/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to delete shared picklist');
    }
  }
}
