import 'dart:convert';

import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ScorePredictorAnalysis extends AnalysisFunction {
  ScorePredictorAnalysis({
    required this.blue1,
    required this.blue2,
    required this.blue3,
    required this.red1,
    required this.red2,
    required this.red3,
  });

  int blue1;
  int blue2;
  int blue3;
  int red1;
  int red2;
  int red3;

  @override
  Future getOnlineAnalysis() async {
    var response = await http.get(Uri.http(
        (await getServerAuthority())!, "/API/analysis/predictWinning", {
      "blue1": blue1.toString(),
      "blue2": blue2.toString(),
      "blue3": blue3.toString(),
      "red1": red1.toString(),
      "red2": red2.toString(),
      "red3": red3.toString(),
    }));

    return jsonDecode(utf8.decode(response.bodyBytes))[0];
  }
}
