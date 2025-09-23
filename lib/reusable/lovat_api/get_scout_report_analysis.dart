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
    required this.bargeResult,
    required this.defense,
    required this.coralL1,
    required this.coralL2,
    required this.coralL3,
    required this.coralL4,
    required this.processorScores,
    required this.netScores,
    required this.netFails,
    required this.autoPath,
    this.notes,
    this.robotBrokeDescription,
  });

  final int totalPoints;
  final DriverAbility driverAbility;
  final RobotRole robotRole;
  final BargeResult bargeResult;
  final int defense;
  final AutoPath autoPath;
  final String? notes;
  final String? robotBrokeDescription;
  final int coralL1;
  final int coralL2;
  final int coralL3;
  final int coralL4;
  final int processorScores;
  final int netScores;
  final int netFails;

  factory SingleScoutReportAnalysis.fromJson(Map<String, dynamic> json) {
    return SingleScoutReportAnalysis(
      totalPoints: json['totalPoints'],
      driverAbility: DriverAbility.values[(json['driverAbility'] as int) - 1],
      robotRole: RobotRole.values[json['role']],
      bargeResult: BargeResult.values[json['barge']],
      defense: json['defends'],
      coralL1: json['coralL1'],
      coralL2: json['coralL2'],
      coralL3: json['coralL3'],
      coralL4: json['coralL4'],
      processorScores: json['processorScores'],
      netScores: json['netScores'],
      netFails: json['netFails'],
      autoPath: AutoPath.fromMapSingleMatch(json['autoPath']),
      notes: (json['note'] as String).isEmpty ? null : json['note'],
      // robotBrokeDescription: (json['robotBrokeDescription']),
      robotBrokeDescription:
          "Hard-coded breaking text that might, on occasion, span multiple lines.",
    );
  }
}
