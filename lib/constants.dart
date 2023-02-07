import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

RegExp validServerAuthority = RegExp(
    "^((((?!-))(xn--)?[a-zA-Z0-9][a-zA-Z0-9-_]{0,61}[a-zA-Z0-9]{0,1}\\.(xn--)?([a-zA-Z0-9\\-]{1,61}|[a-zA-Z0-9-]{1,30}\\.[a-zA-Z]{2,}))|(localhost))(:\\d+)?\$");

List<Tournament> tournamentList = <Tournament>[
  if (kDebugMode) Tournament("2022cc", "Chezy 2022 (debug)"),
];

// Picklists

final List<PicklistWeight> picklistWeights = [
  PicklistWeight('defenseScore', 'Defense score'),
  PicklistWeight('teleopScore', 'Teleop score'),
  PicklistWeight('coneOneScore', 'Cones L1'),
  PicklistWeight('coneTwoScore', 'Cones L2'),
  PicklistWeight('coneThreeScore', 'Cones L3'),
  PicklistWeight('cubeOneScore', 'Cubes L1'),
  PicklistWeight('cubeTwoScore', 'Cubes L2'),
  PicklistWeight('cubeThreeScore', 'Cubes L3'),
  PicklistWeight('autoCargo', 'Auto cargo'),
  PicklistWeight('autoClimb', 'Auto climb'),
];

List<ConfiguredPicklist> defaultPicklists = <ConfiguredPicklist>[
  ConfiguredPicklist.defaultWeights('Overall'),
];

enum AutoPathPosition {
  none,
}

final Map<AutoPathPosition, Offset> autoPositions = {};

Tournament? getTournamentByKey(String key) {
  try {
    return tournamentList.firstWhere((tournament) => tournament.key == key);
  } on StateError {
    return null;
  }
}

Future<String?> getServerAuthority() async {
  final prefs = await SharedPreferences.getInstance();

  return prefs.getString("serverAuthority");
}
