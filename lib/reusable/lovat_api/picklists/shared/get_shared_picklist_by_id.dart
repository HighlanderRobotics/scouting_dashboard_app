import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetSharedPicklistById on LovatAPI {
  ConfiguredPicklist? getCachedSharedPicklistById(String id) {
    final response = getCachedResponse('/v1/manager/picklists/$id');
    if (response == null) return null;
    return ConfiguredPicklist.fromServerJSON(response.body);
  }

  Future<ConfiguredPicklist> getSharedPicklistById(String id) async {
    final response = await get('/v1/manager/picklists/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get shared picklist');
    }

    return ConfiguredPicklist.fromServerJSON(response!.body);
  }
}
