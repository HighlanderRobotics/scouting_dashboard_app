import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:uuid/uuid.dart';

extension GetTeamCode on LovatAPI {
  Future<String?> getTeamCode() async {
    final response = await get('/v1/manager/code', query: {
      'uuid': const Uuid().v4(),
    });

    if (response?.statusCode == 403) return null;

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get team code');
    }

    return response!.body;
  }
}
