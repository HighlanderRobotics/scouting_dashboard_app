import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';

class PicklistAnalysis extends AnalysisFunction {
  PicklistAnalysis({
    required this.picklist,
  });

  ConfiguredPicklist picklist;

  @override
  Future getOnlineAnalysis() async {
    final flags = await getPicklistFlags();

    final flagStrings = flags.map((e) => e.type.path).toList();

    return await lovatAPI.getPicklistAnalysis(flagStrings, picklist.weights);
  }
}
