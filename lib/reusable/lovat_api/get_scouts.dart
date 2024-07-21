import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetScouts on LovatAPI {
  Future<List<Scout>> getScouts() async {
    final response = await get('/v1/manager/scoutershift/scouters');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get scouts');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => Scout.fromJson(e)).toList();
  }
}
