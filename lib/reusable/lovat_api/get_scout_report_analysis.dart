import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/pages/raw_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
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

    return SingleScoutReportAnalysis.fromJson(jsonDecode(response!.body));
  }
}

class SingleScoutReportAnalysis {
  const SingleScoutReportAnalysis({
    required this.totalPoints,
    required this.driverAbility,
    required this.robotRole,
    required this.defense,
    required this.ampScores,
    required this.speakerScores,
    required this.trapScores,
    required this.pickups,
    required this.autoPath,
    required this.stageResult,
    required this.highNoteResult,
    this.notes,
  });

  final int totalPoints;
  final DriverAbility driverAbility;
  final RobotRole robotRole;
  final int defense;
  final int ampScores;
  final int speakerScores;
  final int trapScores;
  final int pickups;
  final AutoPath autoPath;
  final String? notes;
  final StageResult stageResult;
  final HighNoteResult highNoteResult;

  factory SingleScoutReportAnalysis.fromJson(Map<String, dynamic> json) {
    return SingleScoutReportAnalysis(
      totalPoints: json['totalPoints'],
      driverAbility: DriverAbility.values[(json['driverAbility'] as int) - 1],
      robotRole: RobotRole.values[json['role']],
      defense: json['defense'],
      ampScores: json['ampscores'],
      speakerScores: json['speakerscores'],
      trapScores: json['trapscores'],
      pickups: json['pickups'],
      autoPath: AutoPath.fromMapSingleMatch(json['autoPath']),
      notes: (json['note'] as String).isEmpty ? null : json['note'],
      stageResult: StageResult.values[json['stage']],
      highNoteResult: HighNoteResult.values[json['highNote']],
    );
  }
}
