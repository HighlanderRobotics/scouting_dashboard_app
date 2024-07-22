import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_match_prediction.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

class MatchPredictorAnalysis extends AnalysisFunction {
  MatchPredictorAnalysis({
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
    try {
      return await lovatAPI.getMatchPrediction(
          red1, red2, red3, blue1, blue2, blue3);
    } on LovatAPIException catch (e) {
      if (e.message == "Not enough data") {
        return "not enough data";
      } else {
        rethrow;
      }
    }
  }
}
