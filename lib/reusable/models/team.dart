import 'package:scouting_dashboard_app/reusable/lovat_api.dart';

class Team {
  const Team({
    required this.name,
    required this.number,
  });

  final String name;
  final int number;

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        name: json['team']['name'] as String,
        number: json['team']['number'] as int,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
      };

  Future<RegistrationStatusResponse> getRegistrationStatus() =>
      lovatAPI.getRegistrationStatus(number);
}
