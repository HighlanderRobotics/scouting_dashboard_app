import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/robot_roles.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';

class AllianceTeam {
  const AllianceTeam({
    required this.team,
    this.role,
    this.averagePoints,
    this.paths = const [],
  });

  final int team;
  final int? role;
  final double? averagePoints;
  final List<AutoPath> paths;

  RobotRoles? get robotRole => role == null ? null : RobotRoles.values[role!];

  factory AllianceTeam.fromJson(Map<String, dynamic> json) {
    return AllianceTeam(
      team: json['team'] as int,
      role: json['role'] as int?,
      averagePoints: (json['averagePoints'] as num?)?.toDouble(),
      paths: (json['paths'] as List<dynamic>? ?? [])
          .map((e) => AutoPath.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AllianceAnalysis {
  const AllianceAnalysis({
    required this.teams,
    required this.totalPoints,
    required this.l1StartTime,
    required this.l2StartTime,
    required this.l3StartTime,
    required this.totalFuelOutputted,
    required this.totalBallThroughput,
  });

  final List<AllianceTeam> teams;
  final double? totalPoints;
  final List<num?> l1StartTime;
  final List<num?> l2StartTime;
  final List<num?> l3StartTime;
  final num totalFuelOutputted;
  final num totalBallThroughput;

  factory AllianceAnalysis.fromJson(Map<String, dynamic> json) {
    return AllianceAnalysis(
      teams: (json['teams'] as List<dynamic>)
          .map((e) => AllianceTeam.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPoints: (json['totalPoints'] as num?)?.toDouble(),
      l1StartTime: (json['l1StartTime'] as List<dynamic>).cast<num?>(),
      l2StartTime: (json['l2StartTime'] as List<dynamic>).cast<num?>(),
      l3StartTime: (json['l3StartTime'] as List<dynamic>).cast<num?>(),
      totalFuelOutputted: json['totalFuelOutputted'] as num,
      totalBallThroughput: json['totalBallThroughput'] as num,
    );
  }
}

extension AllianceAnalysisQuery on LovatAPI {
  CachedQuery<AllianceAnalysis> allianceAnalysisQuery(List<int> teams) {
    const path = '/v1/analysis/alliance';
    final query = {
      'teamOne': teams[0].toString(),
      'teamTwo': teams[1].toString(),
      'teamThree': teams[2].toString(),
    };
    return CachedQuery(
      queryKey: ['allianceAnalysis', teams[0], teams[1], teams[2]],
      queryFn: () async {
        final response = await get(path, query: query);

        if (response?.statusCode != 200) {
          debugPrint(response?.body ?? '');
          throw Exception('Failed to get alliance analysis');
        }

        return AllianceAnalysis.fromJson(
          jsonDecode(response!.body) as Map<String, dynamic>,
        );
      },
      cacheReader: () => getCachedData(
        path,
        query: query,
        parser: (json) =>
            AllianceAnalysis.fromJson(json as Map<String, dynamic>),
      ),
    );
  }
}
