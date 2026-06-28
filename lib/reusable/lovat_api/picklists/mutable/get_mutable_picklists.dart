import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';

extension GetMutablePicklists on LovatAPI {
  CachedQuery<List<MutablePicklistMeta>> mutablePicklists() {
    const path = '/v1/manager/mutablepicklists';
    return CachedQuery(
      queryKey: const ['mutablePicklists'],
      queryFn: () async {
        final response = await get(path);

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
      },
      cacheReader: () => getCachedData(
        path,
        parser: (json) => (json as List<dynamic>)
            .map((e) => MutablePicklistMeta.fromJson(e))
            .toList(),
      ),
    );
  }
}
