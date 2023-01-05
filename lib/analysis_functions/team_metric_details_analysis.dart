import 'dart:convert';

import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/metrics.dart';

import 'package:http/http.dart' as http;

import '../constants.dart';

class TeamMetricDetailsAnalysis extends AnalysisFunction {
  TeamMetricDetailsAnalysis({
    required this.teamNumber,
    required this.metric,
  });

  int teamNumber;
  Metric metric;

  @override
  Future getOnlineAnalysis() async {
    var response = await http.get(Uri.http(
        (await getServerAuthority())!, "/API/analysis/${metric.path}", {
      "team": teamNumber.toString(),
    }));

    return jsonDecode(utf8.decode(response.bodyBytes))[0];
  }
}
