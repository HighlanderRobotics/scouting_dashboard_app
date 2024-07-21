import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension SourceTournamentSettings on LovatAPI {
  Future<void> setSourceTournamentKeys(List<String> tournamentKeys) async {
    final response = await post(
      '/v1/manager/settings/tournamentsource',
      body: {
        'tournaments': tournamentKeys,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to set source tournaments');
    }
  }

  Future<void> setSourceTournaments(List<Tournament> tournaments) async {
    await setSourceTournamentKeys(tournaments.map((e) => e.key).toList());
  }

  Future<List<String>> getSourceTournamentKeys() async {
    final response = await get('/v1/manager/settings/tournamentsource');

    if (response?.statusCode != 200) {
      throw Exception('Failed to get source tournament keys');
    }

    return (jsonDecode(response!.body) as List<dynamic>).cast<String>();
  }
}
