import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetSharedPicklistById on LovatAPI {
  Future<ConfiguredPicklist> getSharedPicklistById(String id) async {
    final response = await get('/v1/manager/picklists/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get shared picklist');
    }

    return ConfiguredPicklist.fromServerJSON(response!.body);
  }
}
