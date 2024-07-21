import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetMutablePicklists on LovatAPI {
  Future<List<MutablePicklistMeta>> getMutablePicklists() async {
    final response = await get('/v1/manager/mutablepicklists');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');

      if (response?.body ==
          'Not authortized to get mutable picklists because your not on a team') {
        throw const LovatAPIException('Not on team');
      }

      throw Exception('Failed to get mutable picklists');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => MutablePicklistMeta.fromJson(e)).toList();
  }
}
