import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/metrics.dart';

import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_metric_details.dart';

class TeamMetricDetailsAnalysis extends AnalysisFunction {
  TeamMetricDetailsAnalysis({
    required this.teamNumber,
    required this.metric,
  });

  int teamNumber;
  CategoryMetric metric;

  @override
  Future getOnlineAnalysis() async {
    return await lovatAPI.getMetricDetails(teamNumber, metric.path);
  }
}
