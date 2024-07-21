import 'package:flutter/foundation.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

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
