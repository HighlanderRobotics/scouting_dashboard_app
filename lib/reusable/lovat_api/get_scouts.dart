import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/scout_schedule.dart';

List<Scout>? cachedScouters;

extension GetScouts on LovatAPI {
  List<Scout>? get cachedScouts => cachedScouters;

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

    cachedScouters = json.map((e) => Scout.fromJson(e)).toList();
    cachedScouters?.sort((a, b) => a.name.trim().compareTo(b.name.trim()));
    return cachedScouters!;
  }
}
