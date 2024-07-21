import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetSharedPicklists on LovatAPI {
  Future<List<ConfiguredPicklistMeta>> getSharedPicklists() async {
    final response = await get('/v1/manager/picklists');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');

      if (response?.body ==
          'Not authortized to get mutable picklists because your not on a team') {
        throw const LovatAPIException('Not on team');
      }

      throw Exception('Failed to get shared picklists');
    }

    List<dynamic> parsedResponse = jsonDecode(response!.body);

    debugPrint(parsedResponse.toString());

    return parsedResponse
        .map((e) => ConfiguredPicklistMeta.fromJson(e))
        .toList();
  }
}
