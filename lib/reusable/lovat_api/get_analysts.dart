import 'dart:convert';

import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetAnalysts on LovatAPI {
  Future<List<Analyst>?> getAnalysts() async {
    final response = await get('/v1/manager/analysts');

    if ([403, 404].contains(response?.statusCode)) {
      return null;
    }

    if (response?.statusCode != 200) {
      throw Exception('Failed to get analysts');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => Analyst.fromJson(e)).toList();
  }
}
