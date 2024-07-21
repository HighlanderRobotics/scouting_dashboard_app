import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/pages/match_schedule.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetMatches on LovatAPI {
  Future<List<MatchScheduleMatch>> getMatches(
    String tournamentKey, {
    bool? isScouted,
    List<int>? teamNumbers,
  }) async {
    final response = await get(
      "/v1/manager/matches/$tournamentKey",
      query: {
        if (isScouted != null) 'isScouted': isScouted.toString(),
        if (teamNumbers != null) 'teams': jsonEncode(teamNumbers),
      },
    );

    if (response?.statusCode == 404) {
      throw const LovatAPIException(
          'No matches found. This is likely because the match schedule has not been posted on The Blue Alliance yet. Please try again later.');
    }

    if (response?.body ==
        'tournament not found when trying to insert tournament matches') {
      throw const LovatAPIException('Tournament not found');
    }

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');

      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to get match schedule');
      }
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    debugPrint(response.body);

    return json.map((e) => MatchScheduleMatch.fromJson(e)).toList();
  }
}

class MatchScheduleMatch {
  const MatchScheduleMatch({
    required this.identity,
    required this.isScouted,
    required this.red1,
    required this.red2,
    required this.red3,
    required this.blue1,
    required this.blue2,
    required this.blue3,
  });

  final GameMatchIdentity identity;

  final MatchScheduleTeamInfo red1;
  final MatchScheduleTeamInfo red2;
  final MatchScheduleTeamInfo red3;
  final MatchScheduleTeamInfo blue1;
  final MatchScheduleTeamInfo blue2;
  final MatchScheduleTeamInfo blue3;

  final bool isScouted;

  List<MatchScheduleTeamInfo> get allTeamInfo => [
        red1,
        red2,
        red3,
        blue1,
        blue2,
        blue3,
      ];

  factory MatchScheduleMatch.fromJson(Map<String, dynamic> json) {
    return MatchScheduleMatch(
      identity: GameMatchIdentity(MatchType.values[json['matchType']],
          json['matchNumber'], json['tournamentKey']),
      isScouted: json['scouted'],
      red1: MatchScheduleTeamInfo.fromJson(json['team1']),
      red2: MatchScheduleTeamInfo.fromJson(json['team2']),
      red3: MatchScheduleTeamInfo.fromJson(json['team3']),
      blue1: MatchScheduleTeamInfo.fromJson(json['team4']),
      blue2: MatchScheduleTeamInfo.fromJson(json['team5']),
      blue3: MatchScheduleTeamInfo.fromJson(json['team6']),
    );
  }
}

class MatchScheduleTeamInfo {
  const MatchScheduleTeamInfo({
    required this.teamNumber,
    required this.alliance,
    required this.scouters,
    required this.externalReportCount,
  });

  final int teamNumber;
  final Alliance alliance;
  final List<MatchScheduleScouterInfo> scouters;
  final int externalReportCount;

  factory MatchScheduleTeamInfo.fromJson(Map<String, dynamic> json) {
    return MatchScheduleTeamInfo(
      teamNumber: json['number'],
      alliance: AllianceExtension.fromString(json['alliance']),
      scouters: (json['scouters'] as List<dynamic>)
          .map((e) => MatchScheduleScouterInfo.fromJson(e))
          .toList(),
      externalReportCount: json['externalReports'],
    );
  }
}

class MatchScheduleScouterInfo {
  const MatchScheduleScouterInfo({
    required this.name,
    required this.isScouted,
  });

  final String name;
  final bool isScouted;

  factory MatchScheduleScouterInfo.fromJson(Map<String, dynamic> json) {
    return MatchScheduleScouterInfo(
      name: json['name'],
      isScouted: json['scouted'],
    );
  }
}
