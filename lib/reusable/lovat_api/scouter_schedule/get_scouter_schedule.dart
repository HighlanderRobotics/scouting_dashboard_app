import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/scout_schedule.dart';

extension GetScouterSchedule on LovatAPI {
  ServerScoutSchedule? getCachedScouterSchedule(String tournamentKey) {
    return getCachedData(
      '/v1/manager/tournament/$tournamentKey/scoutershifts',
      parser: (json) =>
          ServerScoutSchedule.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ServerScoutSchedule> getScouterSchedule() async {
    final tournament = await Tournament.getCurrent();

    if (tournament == null) {
      throw Exception('No tournament selected');
    }

    final response =
        await get('/v1/manager/tournament/${tournament.key}/scoutershifts');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get scouter schedule');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return ServerScoutSchedule.fromJson(json);
  }
}
