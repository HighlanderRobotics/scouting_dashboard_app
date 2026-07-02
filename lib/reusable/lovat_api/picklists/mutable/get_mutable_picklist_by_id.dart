import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetMutablePicklistById on LovatAPI {
  MutablePicklist? getCachedMutablePicklistById(String id) {
    final response = getCachedResponse('/v1/manager/mutablepicklists/$id');
    if (response == null) return null;
    return MutablePicklist.fromJSON(response.body);
  }

  Future<MutablePicklist> getMutablePicklistById(String id) async {
    final response = await get('/v1/manager/mutablepicklists/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get mutable picklist');
    }

    return MutablePicklist.fromJSON(response!.body);
  }
}
