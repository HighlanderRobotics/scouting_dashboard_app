import 'dart:convert';

import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class PicklistAnalysis extends AnalysisFunction {
  PicklistAnalysis({
    required this.picklist,
  });

  ConfiguredPicklist picklist;

  @override
  Future getOnlineAnalysis() async {
    Map<String, dynamic> params =
        picklist.weights.asMap().map((key, value) => MapEntry(
              value.path,
              value.value.toString(),
            ));

    params['tournamentKey'] =
        (await SharedPreferences.getInstance()).getString('tournament');

    var response = await http.get(Uri.http(
        (await getServerAuthority())!, "/API/analysis/picklist", params));

    print(response.body);

    return (jsonDecode(utf8.decode(response.bodyBytes))[0]['result']
        as List<dynamic>);
  }
}
