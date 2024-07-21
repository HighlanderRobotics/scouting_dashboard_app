import 'dart:convert';

import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetTournaments on LovatAPI {
  Future<PartialTournamentList> getTournaments({
    int? take,
    int? skip,
    String filter = '',
  }) async {
    final response = await get(
      '/v1/manager/tournaments',
      query: {
        if (take != null) 'take': take.toString(),
        if (skip != null) 'skip': skip.toString(),
        'filter': filter,
      },
    );

    if (response?.statusCode != 200) {
      throw Exception('Failed to get tournaments');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;
    final tournamentJson = json['tournaments'] as List<dynamic>;

    final tournaments =
        tournamentJson.map((e) => Tournament.fromJson(e)).toList();

    return PartialTournamentList(
      tournaments: tournaments,
      total: json['count'],
    );
  }
}

class PartialTournamentList {
  const PartialTournamentList({
    required this.tournaments,
    required this.total,
  });

  final List<Tournament> tournaments;
  final int total;
}
