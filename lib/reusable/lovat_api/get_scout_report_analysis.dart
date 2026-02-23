import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/raw_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/robot_roles.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';

extension GetScoutReportAnalysis on LovatAPI {
  Future<SingleScoutReportAnalysis> getScoutReportAnalysis(
    String reportId,
  ) async {
    final response = await get('/v1/analysis/metrics/scoutreport/$reportId');
    debugPrint(response?.body ?? '');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get scout report analysis');
    }

    final json = jsonDecode(response!.body);
    //final json = jsonDecode(
    //    '{"totalPoints":200,"driverAbility":0,"robotRoles":[0,1,2,3,4],"climb":3,"autoClimb":0,"autoClimbStartTime":0,"contactDefenseTime":0,"campingDefenseTime":0,"scoringRate":12.3,"feedingRate":10.7,"defenseEffectiveness":0,"feeds":0, "volleys": 3, "ballsFed": 23, "accuracy":4,"feederType":[0],"climbResult":0,"climbStartTime":0,"autoPath":{"autoPoints":60,"positions":[{"location":2,"event":0,"time":2},{"location":2,"event":1,"time":7},{"location":0,"event":2,"time":0},{"location":5,"event":7,"time":1},{"location":7,"event":1,"time":13},{"location":5,"event":4,"time":0},{"location":7,"event":7,"time":0}],"match":"2025casf_qm3_5","tournamentName":"San Francisco Regional"},"note":"this is a test disregard","robotBrokeDescription":"robot go boom","timeStamp":"1970-01-01T00:00:00.000Z"}');

    return SingleScoutReportAnalysis.fromJson(json);
  }
}

class SingleScoutReportAnalysis {
  const SingleScoutReportAnalysis({
    required this.totalPoints,
    required this.driverAbility,
    required this.robotRoles,
    required this.autoClimb,
    required this.autoClimbStartTime,
    required this.contactDefenseTime,
    required this.campingDefenseTime,
    required this.scoringRate,
    required this.feedingRate,
    required this.defenseEffectiveness,
    required this.feeds,
    required this.climbResult,
    required this.climbStartTime,
    required this.feederType,
    required this.autoPath,
    required this.accuracy,
    required this.volleys,
    required this.ballsFed,
    required this.ballsPerFeed,
    required this.autoScore,
    this.notes,
    this.robotBrokeDescription,
  });

  final int totalPoints;
  final num driverAbility;
  final List<RobotRoles> robotRoles;
  final AutoClimbResult autoClimb;
  final num autoClimbStartTime;
  final num contactDefenseTime;
  final num campingDefenseTime;
  final num scoringRate;
  final num feedingRate;
  final num defenseEffectiveness;
  final num feeds;
  final num accuracy;
  final EndgameClimbResult climbResult;
  final num climbStartTime;
  final List<FeederType> feederType;
  final AutoPath autoPath;
  final num volleys;
  final num ballsFed;
  final num ballsPerFeed;
  final num autoScore;
  final String? notes;
  final String? robotBrokeDescription;

  factory SingleScoutReportAnalysis.fromJson(Map<String, dynamic> json) {
    return SingleScoutReportAnalysis(
      totalPoints: json['totalPoints'],
      driverAbility:
          DriverAbility.values[(json['driverAbility'] - 1)].index + 1,
      robotRoles: ((json['robotRoles'] as List<dynamic>).cast<int>())
          .map<RobotRoles>((elem) => RobotRoles.values[elem])
          .toList(),
      feederType: ((json['feederType'] as List<dynamic>).cast<int>())
          .map<FeederType>((elem) => FeederType.values[elem])
          .toList(),
      scoringRate: json['scoringRate'],
      feedingRate: json['feedingRate'],
      autoClimbStartTime: json['autoClimbStartTime'],
      contactDefenseTime: json['contactDefenseTime'],
      campingDefenseTime: json['campingDefenseTime'],
      defenseEffectiveness: json["defenseEffectiveness"] + 1,
      feeds: json["feeds"],
      accuracy: json["accuracy"],
      climbStartTime: json["climbStartTime"],
      climbResult: EndgameClimbResult.values[(json['climbResult'] as int)],
      autoClimb: AutoClimbResult.values[(json['autoClimb'] as int)],
      autoPath: AutoPath.fromMapSingleMatch(json["autoPath"]),
      autoScore: json["autoPath"]["autoPoints"],
      volleys: json["volleys"],
      ballsFed: json["totalBallsFed"],
      ballsPerFeed:
          json["volleys"] != 0 ? json["totalBallsFed"] / json["volleys"] : 0,
      notes: (json['note'] as String).isEmpty ? null : json['note'],
      robotBrokeDescription: json['robotBrokeDescription'],
    );
  }
}
