import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';

extension GetSharedPicklists on LovatAPI {
  CachedQuery<List<ConfiguredPicklistMeta>> sharedPicklists() {
    const path = '/v1/manager/picklists';
    return CachedQuery(
      queryKey: const ['sharedPicklists'],
      queryFn: () async {
        final response = await get(path);

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
      },
      cacheReader: () => getCachedData(
        path,
        parser: (json) => (json as List<dynamic>)
            .map((e) => ConfiguredPicklistMeta.fromJson(e))
            .toList(),
      ),
    );
  }
}
