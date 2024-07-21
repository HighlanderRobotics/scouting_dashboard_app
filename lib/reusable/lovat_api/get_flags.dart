import 'dart:convert';

import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetFlags on LovatAPI {
  Future<List<dynamic>> getFlags(List<String> paths, int teamNumber) async {
    final tournament = await Tournament.getCurrent();

    final response = await get(
      '/v1/analysis/flag/team/$teamNumber',
      query: {
        if (tournament != null) 'tournamentKey': tournament.key,
        'flags': jsonEncode(paths),
      },
    );

    if (response?.statusCode != 200) {
      throw Exception('Failed to get flags');
    }

    return jsonDecode(response!.body) as List<dynamic>;
  }

  Future<dynamic> getFlag(path, teamNumber) async {
    return (await getFlags([path], teamNumber)).first;
  }
}
