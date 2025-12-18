import 'dart:convert';

import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/match.dart';

extension GetScoutReportsByScouter on LovatAPI {
  Future<List<ScouterPageMinimalScoutReportInfo>> getScoutReportsByScouter(
    String scouterId,
  ) async {
    final tournament = await Tournament.getCurrent();

    final response = await lovatAPI.get(
      '/v1/manager/scouterreports',
      query: {
        'scouterUuid': scouterId,
        if (tournament != null) 'tournamentKey': tournament.key,
      },
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to get scout reports by scouter');
      }
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json
        .map((e) => ScouterPageMinimalScoutReportInfo.fromJson(e))
        .toList();
  }
}

class ScouterPageMinimalScoutReportInfo {
  const ScouterPageMinimalScoutReportInfo({
    required this.matchIdentity,
    required this.reportId,
    required this.teamNumber,
  });

  final GameMatchIdentity matchIdentity;
  final String reportId;
  final int teamNumber;

  factory ScouterPageMinimalScoutReportInfo.fromJson(
      Map<String, dynamic> json) {
    return ScouterPageMinimalScoutReportInfo(
      matchIdentity: GameMatchIdentity.fromLongKey(
        json['teamMatchData']['key'],
        tournamentName: json['teamMatchData']['tournament']['name'],
      ),
      reportId: json['uuid'],
      teamNumber: json['teamMatchData']['teamNumber'],
    );
  }
}
