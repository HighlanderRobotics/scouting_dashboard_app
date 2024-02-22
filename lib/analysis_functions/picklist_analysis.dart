import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';

abstract class PicklistAnalysis extends AnalysisFunction {
  @override
  Future<Map<String, List<dynamic>>> getOnlineAnalysis() async {
    throw UnimplementedError();
  }

  ConfiguredPicklistMeta get picklistMeta => throw UnimplementedError();
}

class MyPicklistAnalysis extends PicklistAnalysis {
  MyPicklistAnalysis({
    required this.picklist,
  });

  ConfiguredPicklist picklist;

  @override
  Future<Map<String, List<dynamic>>> getOnlineAnalysis() async {
    final flags = await getPicklistFlags();

    final flagStrings = flags.map((e) => e.type.path).toList();

    return {
      ...(await lovatAPI.getPicklistAnalysis(flagStrings, picklist.weights)),
      "flags": flags,
    };
  }

  @override
  ConfiguredPicklistMeta get picklistMeta => picklist.meta;
}

class SharedPicklistAnalysis extends PicklistAnalysis {
  SharedPicklistAnalysis({
    required this.picklistMeta,
  });

  @override
  ConfiguredPicklistMeta picklistMeta;

  @override
  Future<Map<String, List<dynamic>>> getOnlineAnalysis() async {
    final flags = await getPicklistFlags();

    final flagStrings = flags.map((e) => e.type.path).toList();

    final picklist = await picklistMeta.getPicklist();

    return {
      ...(await lovatAPI.getPicklistAnalysis(flagStrings, picklist.weights)),
      "flags": flags,
    };
  }
}
