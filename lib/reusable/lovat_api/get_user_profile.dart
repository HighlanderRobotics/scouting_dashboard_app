import 'dart:convert';

import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/user_profile.dart';

extension GetUserProfile on LovatAPI {
  Future<LovatUserProfile> getUserProfile() async {
    final response = await get('/v1/manager/profile');

    if (response?.statusCode != 200) {
      throw Exception('Failed to get user profile: ${response?.statusCode}');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return LovatUserProfile.fromJson(json);
  }
}
