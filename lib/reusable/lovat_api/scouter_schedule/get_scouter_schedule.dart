import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetScouterSchedule on LovatAPI {
  Future<ServerScoutSchedule> getScouterSchedule() async {
    final tournament = await Tournament.getCurrent();

    if (tournament == null) {
      throw Exception('No tournament selected');
    }

    final response =
        await get('/v1/manager/tournament/${tournament.key}/scoutershifts');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get scouter schedule');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return ServerScoutSchedule.fromJson(json);
  }
}
