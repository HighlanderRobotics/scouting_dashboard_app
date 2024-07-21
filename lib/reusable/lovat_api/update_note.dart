import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension UpdateNote on LovatAPI {
  Future<void> updateNote(String noteUuid, String newBody) async {
    final response = await put(
      '/v1/manager/notes/$noteUuid',
      body: {
        'note': newBody,
      },
    );

    debugPrint(response?.body ?? '');

    if (response?.statusCode != 200) {
      throw Exception('Failed to update note');
    }
  }
}
