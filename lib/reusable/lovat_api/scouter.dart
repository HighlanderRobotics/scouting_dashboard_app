import 'dart:convert';

import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension Scouter on LovatAPI {
  Future<void> addScouter(String name) async {
    final response = await lovatAPI.post(
      '/v1/manager/scouterdashboard',
      body: {
        'name': name,
      },
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to add scouter');
      }
    }
  }

  Future<void> deleteScouter(String id) async {
    final response = await lovatAPI.delete(
      '/v1/manager/scouterdashboard',
      body: {
        'scouterUuid': id,
      },
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to delete scouter');
      }
    }
  }

  Future<void> renameScouter(String id, String newName) async {
    final response = await lovatAPI.put(
      '/v1/manager/scoutername',
      body: {
        'scouterUuid': id,
        'newName': newName,
      },
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to rename scouter');
      }
    }
  }
}
