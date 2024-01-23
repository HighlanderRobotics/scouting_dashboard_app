import 'dart:convert';

import 'package:flutter/widgets.dart';

class LovatUserProfile {
  const LovatUserProfile({
    required this.email,
    this.username,
    this.teamNumber,
  });

  final String email;
  final String? username;
  final int? teamNumber;

  factory LovatUserProfile.fromJson(Map<String, dynamic> json) {
    debugPrint(jsonEncode(json));

    return LovatUserProfile(
      email: json['email'],
      username: json['username'],
      teamNumber: json['teamNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'team': teamNumber,
    };
  }
}
