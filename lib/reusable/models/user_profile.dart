import 'dart:convert';

import 'package:flutter/widgets.dart';
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
    debugPrint(jsonEncode(json));

    return LovatUserProfile(
      email: json['email'],
      username: json['username'],
      team: json.containsKey('team') ? Team.fromJson(json['team']) : null,
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
