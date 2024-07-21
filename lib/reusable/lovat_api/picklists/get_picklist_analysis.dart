import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetPicklistAnalysis on LovatAPI {
  Future<Map<String, List<dynamic>>> getPicklistAnalysis(
    List<String> flags,
    List<PicklistWeight> weights,
  ) async {
    final tournament = await Tournament.getCurrent();

    final response = await get(
      '/v1/analysis/picklist',
      query: {
        if (tournament != null) 'tournamentKey': tournament.key,
        'flags': jsonEncode(flags),
        ...Map.fromEntries(
          weights.map((e) => MapEntry(e.path, e.value.toString())).toList(),
        ),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get picklist analysis');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return {
      'result': json['teams'] as List<dynamic>,
    };
  }
}
