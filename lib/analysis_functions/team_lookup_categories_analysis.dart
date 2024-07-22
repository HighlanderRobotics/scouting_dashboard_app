import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_category_metrics.dart';

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
