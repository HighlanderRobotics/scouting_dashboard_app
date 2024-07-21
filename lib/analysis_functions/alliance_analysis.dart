import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

class AllianceAnalysis extends AnalysisFunction {
  AllianceAnalysis({
    required this.teams,
  });

  List<int> teams;

  @override
  Future getOnlineAnalysis() async {
    return await lovatAPI.getAllianceAnalysis(teams);
  }
}
