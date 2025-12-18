import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/scout_schedule.dart';

extension DeleteScouterScheduleShift on LovatAPI {
  Future<void> deleteScoutScheduleShiftById(String id) async {
    final response = await delete('/v1/manager/scoutershifts/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to delete scouter schedule shift');
    }
  }

  Future<void> deleteScoutScheduleShift(ServerScoutingShift shift) async {
    await deleteScoutScheduleShiftById(shift.id);
  }
}
