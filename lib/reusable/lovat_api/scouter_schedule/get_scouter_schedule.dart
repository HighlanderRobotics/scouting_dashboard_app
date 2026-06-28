import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/scout_schedule.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';

extension GetScouterSchedule on LovatAPI {
  CachedQuery<ServerScoutSchedule> scouterSchedule(String tournamentKey) {
    final path = '/v1/manager/tournament/$tournamentKey/scoutershifts';
    return CachedQuery(
      queryKey: ['scouterSchedule', tournamentKey],
      queryFn: () async {
        final response = await get(path);

        if (response?.statusCode != 200) {
          debugPrint(response?.body ?? '');
          throw Exception('Failed to get scouter schedule');
        }

        final json = jsonDecode(response!.body) as Map<String, dynamic>;

        return ServerScoutSchedule.fromJson(json);
      },
      cacheReader: () => getCachedData(
        path,
        parser: (json) =>
            ServerScoutSchedule.fromJson(json as Map<String, dynamic>),
      ),
    );
  }
}
