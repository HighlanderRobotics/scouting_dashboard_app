import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension UpdateScouterScheduleShift on LovatAPI {
  Future<void> updateScouterScheduleShift(
    ServerScoutingShift shift,
  ) async {
    final response = await post(
      '/v1/manager/scoutershifts/${shift.id}',
      body: {
        'startMatchOrdinalNumber': shift.start,
        'endMatchOrdinalNumber': shift.end,
        'team1': shift.team1.map((e) => e.id).toList(),
        'team2': shift.team2.map((e) => e.id).toList(),
        'team3': shift.team3.map((e) => e.id).toList(),
        'team4': shift.team4.map((e) => e.id).toList(),
        'team5': shift.team5.map((e) => e.id).toList(),
        'team6': shift.team6.map((e) => e.id).toList(),
      },
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        debugPrint(response?.body ?? '');
        throw Exception('Failed to update scouter schedule shift');
      }
    }
  }
}
