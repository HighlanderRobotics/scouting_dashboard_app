import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension UploadScoutReport on LovatAPI {
  Future<void> uploadScoutReport(String data) async {
    final response = await post(
      '/v1/manager/dashboard/scoutreport',
      body: jsonDecode(data),
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');

      late final Exception exception;

      try {
        exception =
            LovatAPIException(jsonDecode(response!.body)['displayError']);
      } catch (_) {
        exception = Exception('Failed to upload scout report');
      }

      throw exception;
    }
  }
}
