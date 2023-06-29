import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/constants.dart';

class TeamLookupBreakdownsAnalysis extends AnalysisFunction {
  TeamLookupBreakdownsAnalysis({
    required this.team,
  });

  int team;

  @override
  Future getOnlineAnalysis() async {
    var response = await http.get(Uri.http(
        (await getServerAuthority())!, "/API/analysis/breakdownMetrics", {
      "team": team.toString(),
    }));

    return jsonDecode(utf8.decode(response.bodyBytes))[0]['result'];
  }
}
