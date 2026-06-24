import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_alliance_analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

class MatchPrediction {
  const MatchPrediction({
    required this.redWinning,
    required this.blueWinning,
    required this.redAlliance,
    required this.blueAlliance,
  });

  final num? redWinning;
  final num? blueWinning;
  final AllianceAnalysis redAlliance;
  final AllianceAnalysis blueAlliance;

  factory MatchPrediction.fromJson(Map<String, dynamic> json) {
    return MatchPrediction(
      redWinning: json['redWinning'] as num?,
      blueWinning: json['blueWinning'] as num?,
      redAlliance: AllianceAnalysis.fromJson(
        json['redAlliance'] as Map<String, dynamic>,
      ),
      blueAlliance: AllianceAnalysis.fromJson(
        json['blueAlliance'] as Map<String, dynamic>,
      ),
    );
  }
}

extension GetMatchPrediction on LovatAPI {
  MatchPrediction? getCachedMatchPrediction(
    int red1,
    int red2,
    int red3,
    int blue1,
    int blue2,
    int blue3,
  ) {
    return getCachedData(
      '/v1/analysis/matchprediction',
      query: {
        'red1': red1.toString(),
        'red2': red2.toString(),
        'red3': red3.toString(),
        'blue1': blue1.toString(),
        'blue2': blue2.toString(),
        'blue3': blue3.toString(),
      },
      parser: (json) =>
          MatchPrediction.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MatchPrediction> getMatchPrediction(
    int red1,
    int red2,
    int red3,
    int blue1,
    int blue2,
    int blue3,
  ) async {
    final response = await get(
      '/v1/analysis/matchprediction',
      query: {
        'red1': red1.toString(),
        'red2': red2.toString(),
        'red3': red3.toString(),
        'blue1': blue1.toString(),
        'blue2': blue2.toString(),
        'blue3': blue3.toString(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get match prediction');
    }

    if (response?.body == 'not enough data') {
      throw const LovatAPIException('Not enough data');
    }

    return MatchPrediction.fromJson(
      jsonDecode(response!.body) as Map<String, dynamic>,
    );
  }
}