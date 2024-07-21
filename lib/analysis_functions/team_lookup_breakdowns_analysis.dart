import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

class TeamLookupBreakdownsAnalysis extends AnalysisFunction {
  TeamLookupBreakdownsAnalysis({
    required this.team,
  });

  int team;

  @override
  Future getOnlineAnalysis() async {
    return await lovatAPI.getBreakdownMetricsByTeamNumber(team);
  }
}
