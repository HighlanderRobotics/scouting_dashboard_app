import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension ArchiveScouter on LovatAPI {
  Future<void> archiveScouter(String scouterUuid) async {
    final response = await post('/v1/manager/archive/uuid/$scouterUuid');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to archive scouter $response.statusCode');
    }
  }
}

extension UnarchiveScouter on LovatAPI {
  Future<void> unarchiveScouter(String scouterUuid) async {
    final response = await post('/v1/manager/unarchive/uuid/$scouterUuid');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to unarchive scouter');
    }
  }
}
