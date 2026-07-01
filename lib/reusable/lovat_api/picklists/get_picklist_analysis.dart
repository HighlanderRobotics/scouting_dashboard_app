import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';

class PicklistBreakdownEntry {
  const PicklistBreakdownEntry({
    required this.type,
    required this.result,
  });

  final String type;
  final double result;

  factory PicklistBreakdownEntry.fromJson(Map<String, dynamic> json) {
    return PicklistBreakdownEntry(
      type: json['type'] as String,
      result: (json['result'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PicklistAnalysisTeam {
  const PicklistAnalysisTeam({
    required this.teamNumber,
    required this.result,
    required this.zScoresWeighted,
    required this.zScoresUnweighted,
    required this.flags,
  });

  final int teamNumber;
  final double result;
  final List<PicklistBreakdownEntry> zScoresWeighted;
  final List<PicklistBreakdownEntry> zScoresUnweighted;
  final List<PicklistBreakdownEntry> flags;

  static PicklistAnalysisTeam fromJson(Map<String, dynamic> json) {
    List<PicklistBreakdownEntry> parseEntries(String key) {
      return (json[key] as List<dynamic>? ?? [])
          .map((val) =>
              PicklistBreakdownEntry.fromJson(val as Map<String, dynamic>))
          .toList();
    }

    return PicklistAnalysisTeam(
      teamNumber: json['team'] as int,
      result: (json['result'] as num?)?.toDouble() ?? 0,
      zScoresWeighted: parseEntries('breakdown'),
      zScoresUnweighted: parseEntries('unweighted'),
      flags: parseEntries('flags'),
    );
  }
}

extension PicklistAnalysisQuery on LovatAPI {
  CachedQuery<List<PicklistAnalysisTeam>> picklistAnalysisQuery(
    List<String> flags,
    List<PicklistWeight> weights,
  ) {
    const path = '/v1/analysis/picklist';
    return CachedQuery(
      queryKey: ['picklistAnalysis', flags, weights],
      queryFn: () async {
        final tournament = await Tournament.getCurrent();

        final response = await get(
          path,
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

        return (json['teams'] as List<dynamic>)
            .map((team) =>
                PicklistAnalysisTeam.fromJson(team as Map<String, dynamic>))
            .toList();
      },
      cacheReader: () {
        final tournament = Tournament.currentSync;
        return getCachedData(
          path,
          query: {
            if (tournament != null) 'tournamentKey': tournament.key,
            'flags': jsonEncode(flags),
            ...Map.fromEntries(
              weights.map((e) => MapEntry(e.path, e.value.toString())).toList(),
            ),
          },
          parser: (json) {
            final map = json as Map<String, dynamic>;
            return (map['teams'] as List<dynamic>)
                .map((team) =>
                    PicklistAnalysisTeam.fromJson(team as Map<String, dynamic>))
                .toList();
          },
        );
      },
    );
  }

  /// Fetches the full picklist analysis and returns it as a CSV string.
  /// [flags] are the flag configurations to include.
  /// [weights] are the picklist weights.
  Future<String> getPicklistCSV({
    required List<FlagConfiguration> flags,
    required List<PicklistWeight> weights,
  }) async {
    final flagPaths = flags.map((e) => e.type.path).toList();
    final teams = await picklistAnalysisQuery(flagPaths, weights).queryFn();

    final List<String> columns = [
      "teamNumber",
      "index",
      ...teams.first.zScoresUnweighted.map((e) => "${e.type}_unweighted"),
      ...teams.first.zScoresWeighted.map((e) => "${e.type}_weighted"),
    ];

    final List<List<String>> rows = [
      columns,
      ...teams.map((team) => [
            team.teamNumber.toString(),
            team.result.toString(),
            ...team.zScoresUnweighted.map((e) => e.result.toString()),
            ...team.zScoresWeighted.map((e) => e.result.toString()),
          ]),
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
