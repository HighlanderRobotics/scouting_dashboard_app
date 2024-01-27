import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';

class TeamLookupCategoriesAnalysis extends AnalysisFunction {
  TeamLookupCategoriesAnalysis({
    required this.team,
  });

  int team;

  @override
  Future getOnlineAnalysis() async {
    return await lovatAPI.getCategoryMetricsByTeamNumber(team);
  }
}
