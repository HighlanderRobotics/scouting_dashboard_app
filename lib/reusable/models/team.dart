import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/onboarding/registration_status.dart';

class Team {
  const Team({
    required this.name,
    required this.number,
  });

  final String name;
  final int number;

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        name: json['name'] as String,
        number: json['number'] as int,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
      };

  Future<RegistrationStatusResponse> getRegistrationStatus() =>
      lovatAPI.getRegistrationStatus(number);
}
