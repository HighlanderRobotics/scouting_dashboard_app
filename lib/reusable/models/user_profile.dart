import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';

class LovatUserProfile {
  const LovatUserProfile({
    required this.email,
    this.username,
    this.team,
    this.role,
  });

  final String email;
  final String? username;
  final Team? team;
  final UserRole? role;

  factory LovatUserProfile.fromJson(Map<String, dynamic> json) {
    debugPrint(jsonEncode(json));

    return LovatUserProfile(
      email: json['email'],
      username: json['username'],
      team: json.containsKey('team') && json['team'] != null
          ? Team.fromJson(json['team']['team'])
          : null,
      role: json.containsKey('role')
          ? UserRoleExtension.fromId(json['role'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'team': team?.toJson(),
      'role': role?.id,
    };
  }
}

enum UserRole {
  analyst,
  scoutingLead,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.analyst:
        return "Analyst";
      case UserRole.scoutingLead:
        return "Scouting Lead";
    }
  }

  String get id {
    switch (this) {
      case UserRole.analyst:
        return "ANALYST";
      case UserRole.scoutingLead:
        return "SCOUTING_LEAD";
    }
  }

  static UserRole fromId(String id) {
    switch (id) {
      case "ANALYST":
        return UserRole.analyst;
      case "SCOUTING_LEAD":
        return UserRole.scoutingLead;
      default:
        throw ArgumentError("Invalid user role ID: $id");
    }
  }
}
