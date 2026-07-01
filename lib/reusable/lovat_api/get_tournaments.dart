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

    final now = DateTime.now();
    int compareByDate(Tournament a, Tournament b) {
      final aDays = a.date?.difference(now).inDays.abs();
      final bDays = b.date?.difference(now).inDays.abs();
      if (aDays == null && bDays == null) return 0;
      if (aDays == null) return 1;
      if (bDays == null) return -1;
      return aDays.compareTo(bDays);
    }

    tournaments.sort((a, b) {
      if (a.isParticipant != b.isParticipant) {
        return b.isParticipant ? 1 : -1;
      }
      return compareByDate(a, b);
    });

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
