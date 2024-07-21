import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension CreateMutablePicklist on LovatAPI {
  Future<void> createMutablePicklist(MutablePicklist picklist) async {
    final tournament = await Tournament.getCurrent();

    final response = await post(
      '/v1/manager/mutablepicklists',
      body: {
        'uuid': picklist.uuid,
        'name': picklist.name,
        'teams': picklist.teams,
        'tournamentKey': tournament?.key,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to create mutable picklist');
    }
  }
}
