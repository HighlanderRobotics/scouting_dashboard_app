import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension UpdateMutablePicklist on LovatAPI {
  Future<void> updateMutablePicklist(MutablePicklist picklist) async {
    final response = await put(
      '/v1/manager/mutablepicklists/${picklist.uuid}',
      body: {
        'name': picklist.name,
        'teams': picklist.teams,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to update mutable picklist');
    }
  }
}
