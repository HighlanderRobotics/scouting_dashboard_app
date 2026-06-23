import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/onboarding/onboarding_page.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension SourceTeamSettings on LovatAPI {
  Future<void> setSourceTeams(
    SourceTeamSettingsMode mode, {
    List<int>? teams,
  }) async {
    final response = await post(
      '/v1/manager/settings/teamsource',
      body: {
        'mode': mode.identifier,
        'teams': teams,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to set source teams');
    }
  }

  Future<SourceTeamSettingsResponse> getSourceTeamSettings() async {
    final response = await get('/v1/manager/settings/teamsource');

    if (response?.statusCode != 200) {
      throw Exception('Failed to get source team settings');
    }

    // body can be "THIS_TEAM", "ALL_TEAMS", or "[1, 2, 3]"

    if (response!.body == 'THIS_TEAM') {
      return const SourceTeamSettingsResponse(mode: SourceTeamSettingsMode.thisTeam);
    } else if (response.body == 'ALL_TEAMS') {
      return const SourceTeamSettingsResponse(mode: SourceTeamSettingsMode.allTeams);
    } else {
      return SourceTeamSettingsResponse(
        mode: SourceTeamSettingsMode.specificTeams,
        teams: (jsonDecode(response.body) as List<dynamic>).cast<int>(),
      );
    }
  }
}

class SourceTeamSettingsResponse {
  const SourceTeamSettingsResponse({
    required this.mode,
    this.teams,
  });

  final SourceTeamSettingsMode mode;
  final List<int>? teams;
}