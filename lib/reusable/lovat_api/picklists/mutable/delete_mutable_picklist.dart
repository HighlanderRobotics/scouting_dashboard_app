import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension DeleteMutablePicklist on LovatAPI {
  Future<void> deleteMutablePicklist(String id) async {
    final response = await delete('/v1/manager/mutablepicklists/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to delete mutable picklist');
    }
  }
}
