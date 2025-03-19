import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/analysis_functions/picklist_analysis.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

class PicklistAnalysisTeam {
  const PicklistAnalysisTeam({
    required this.teamNumber,
    required this.result,
    required this.zScoresWeighted,
    required this.zScoresUnweighted,
  });

  final int teamNumber;
  final double result;
  final Map<String, double> zScoresWeighted;
  final Map<String, double> zScoresUnweighted;

  static PicklistAnalysisTeam fromJson(Map<String, dynamic> json) =>
      PicklistAnalysisTeam(
        teamNumber: json['team'],
        result: (json['result'] as num).toDouble(),
        zScoresWeighted: (json['breakdown'] as List<dynamic>).asMap().map(
            (_, val) =>
                MapEntry(val['type'], (val['result'] as num).toDouble())),
        zScoresUnweighted: (json['unweighted'] as List<dynamic>).asMap().map(
            (_, val) =>
                MapEntry(val['type'], (val['result'] as num).toDouble())),
      );
}

extension GetPicklistAnalysis on LovatAPI {
  Future<Map<String, List<dynamic>>> getPicklistAnalysis(
    List<String> flags,
    List<PicklistWeight> weights,
  ) async {
    final tournament = await Tournament.getCurrent();

    final response = await get(
      '/v1/analysis/picklist',
      query: {
        if (tournament != null) 'tournamentKey': tournament.key,
        'flags': jsonEncode(flags),
        ...Map.fromEntries(
          weights.map((e) => MapEntry(e.path, e.value.toString())).toList(),
        ),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get picklist analysis');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return {
      'result': json['teams'] as List<dynamic>,
    };
  }

  Future<String> getPicklistCSV(PicklistAnalysis analysisFunction) async {
    final json = await analysisFunction.getOnlineAnalysis();

    final List<PicklistAnalysisTeam> teams = (json['result'] as List<dynamic>)
        .map((team) => PicklistAnalysisTeam.fromJson(team))
        .toList();

    final List<String> columns = [
      "teamNumber",
      "index",
      ...teams.first.zScoresUnweighted.keys.map((e) => "${e}_unweighted"),
      ...teams.first.zScoresWeighted.keys.map((e) => "${e}_weighted"),
    ];

    final List<List<String>> rows = [
      columns,
      ...teams.map((team) => [
            team.teamNumber.toString(),
            team.result.toString(),
            ...team.zScoresUnweighted.values.map((e) => e.toString()),
            ...team.zScoresWeighted.values.map((e) => e.toString()),
          ]),
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
