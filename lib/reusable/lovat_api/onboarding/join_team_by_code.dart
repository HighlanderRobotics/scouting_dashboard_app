import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension JoinTeamByCode on LovatAPI {
  Future<bool> joinTeamByCode(int teamNumber, String code) async {
    final response = await post(
      '/v1/manager/onboarding/teamcode',
      query: {
        'code': code,
        'team': teamNumber.toString(),
      },
    );

    if (response?.statusCode == 200) {
      return true;
    } else if (response?.statusCode == 404) {
      return false;
    } else {
      throw Exception('Failed to join team');
    }
  }
}
