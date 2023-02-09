import 'dart:convert';

import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';

import 'package:http/http.dart' as http;

import '../constants.dart';

class AllianceAnalysis extends AnalysisFunction {
  AllianceAnalysis({
    required this.teams,
  });

  List<int> teams;

  @override
  Future getOnlineAnalysis() async {
    var response = await http.get(
        Uri.http((await getServerAuthority())!, "/API/analysis/alliancePage", {
      "teamOne": teams[0].toString(),
      "teamTwo": teams[1].toString(),
      "teamThree": teams[2].toString(),
    }));

    return jsonDecode(utf8.decode(response.bodyBytes))[0];
  }
}
