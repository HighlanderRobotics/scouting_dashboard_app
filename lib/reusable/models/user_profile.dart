import 'package:scouting_dashboard_app/reusable/models/team.dart';

class LovatUserProfile {
  const LovatUserProfile({
    required this.email,
    this.username,
    this.team,
  });

  final String email;
  final String? username;
  final Team? team;

  factory LovatUserProfile.fromJson(Map<String, dynamic> json) {
    return LovatUserProfile(
      email: json['email'],
      username: json['username'],
      team: json['team'] != null ? Team.fromJson(json['team']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'team': team?.toJson(),
    };
  }
}
