import 'dart:convert';

import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';

extension GetTeams on LovatAPI {
  Future<PartialTeamList> getTeams({
    int? take,
    int? skip,
    String filter = '',
  }) async {
    final response = await get(
      '/v1/manager/teams',
      query: {
        if (take != null) 'take': take.toString(),
        if (skip != null) 'skip': skip.toString(),
        'filter': filter,
      },
    );

    if (response?.statusCode != 200) {
      throw Exception('Failed to get teams');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;
    final teamJson = json['teams'] as List<dynamic>;

    final teams = teamJson.map((e) => Team.fromJson(e)).toList();

    return PartialTeamList(teams: teams, total: json['count']);
  }
}

class PartialTeamList {
  const PartialTeamList({
    required this.teams,
    required this.total,
  });

  final List<Team> teams;
  final int total;
}
