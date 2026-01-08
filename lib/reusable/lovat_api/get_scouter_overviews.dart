import 'dart:convert';

import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/scout_schedule.dart';

extension GetScouterOverviews on LovatAPI {
  /// archivedScouters - true: show archived scouters only, false: show unarchived scouters only
  Future<List<ScouterOverview>> getScouterOverviews(
      {bool archivedScouters = false}) async {
    final tournament = await Tournament.getCurrent();

    final response = await lovatAPI.get(
      '/v1/manager/scouterspage',
      query: {
        if (tournament != null) 'tournamentKey': tournament.key,
        'archived': archivedScouters.toString(),
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

    return json
        .map((e) => ScouterOverview.fromJson(e, archived: archivedScouters))
        .toList();
  }
}

class ScouterOverview {
  const ScouterOverview({
    required this.totalMatches,
    required this.missedMatches,
    required this.scout,
    this.archived,
  });

  final int totalMatches;
  final int missedMatches;
  final Scout scout;
  final bool? archived;

  factory ScouterOverview.fromJson(Map<String, dynamic> json,
      {bool? archived}) {
    return ScouterOverview(
      archived: archived,
      totalMatches: json['matchesScouted'],
      missedMatches: json['missedMatches'] ?? 0,
      scout: Scout(
        id: json['scouterUuid'],
        name: json['scouterName'],
      ),
    );
  }
}
