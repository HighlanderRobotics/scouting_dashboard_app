import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension SharePicklist on LovatAPI {
  Future<void> sharePicklist(
    ConfiguredPicklist picklist,
  ) async {
    bool isCustom(PicklistWeight weight) =>
        weight.isCustom || weight.path.startsWith('cf_');

    final customWeights = picklist.weights.where(isCustom).toList();

    // POST /v1/manager/picklists
    final response = await post(
      '/v1/manager/picklists',
      body: {
        'name': picklist.title,
        ...Map.fromEntries(
          picklist.weights
              .where((e) => !isCustom(e))
              .map((e) => MapEntry(e.path, e.value)),
        ),
        if (customWeights.isNotEmpty)
          'customFieldWeights': Map.fromEntries(
            customWeights.map((e) => MapEntry(e.path, e.value)),
          ),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to share picklist');
    }
  }
}
