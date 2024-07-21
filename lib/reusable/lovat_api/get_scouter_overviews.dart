import 'dart:convert';

import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetScouterOverviews on LovatAPI {
  Future<List<ScouterOverview>> getScouterOverviews() async {
    final tournament = await Tournament.getCurrent();

    final response = await lovatAPI.get(
      '/v1/manager/scouterspage',
      query: {
        if (tournament != null) 'tournamentKey': tournament.key,
      },
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to get scouter overviews');
      }
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => ScouterOverview.fromJson(e)).toList();
  }
}

class ScouterOverview {
  const ScouterOverview({
    required this.totalMatches,
    required this.missedMatches,
    required this.scout,
  });

  final int totalMatches;
  final int missedMatches;
  final Scout scout;

  factory ScouterOverview.fromJson(Map<String, dynamic> json) {
    return ScouterOverview(
      totalMatches: json['matchesScouted'],
      missedMatches: json['missedMatches'] ?? 0,
      scout: Scout(
        id: json['scouterUuid'],
        name: json['scouterName'],
      ),
    );
  }
}
