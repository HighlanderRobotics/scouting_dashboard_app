import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';

extension GetTeamsAtTournament on LovatAPI {
  Future<List<Team>> getTeamsAtTournament(String tournamentKey) async {
    final response = await get("/v1/manager/tournament/$tournamentKey/teams");

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get teams at tournament');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => Team.fromJson(e)).toList();
  }
}
