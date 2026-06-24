import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/scout_schedule.dart';

extension GetScouts on LovatAPI {
  List<Scout>? getCachedScouts({bool archivedScouters = false}) {
    final result = getCachedData(
      '/v1/manager/scoutershift/scouters',
      query: {
        'archived': archivedScouters.toString(),
      },
      parser: (json) =>
          (json as List<dynamic>).map((e) => Scout.fromJson(e)).toList(),
    );
    result?.sort((a, b) => a.name.trim().compareTo(b.name.trim()));
    return result;
  }

  /// archivedScouters - true: show archived scouters only, false: show unarchived scouters only
  Future<List<Scout>> getScouts({bool archivedScouters = false}) async {
    final response = await get(
      '/v1/manager/scoutershift/scouters',
      query: {
        'archived': archivedScouters.toString(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get scouts');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    final scouts = json.map((e) => Scout.fromJson(e)).toList();
    scouts.sort((a, b) => a.name.trim().compareTo(b.name.trim()));
    return scouts;
  }
}
