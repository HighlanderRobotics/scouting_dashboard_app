import 'dart:ui';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

RegExp validServerAuthority = RegExp(
    "^((((?!-))(xn--)?[a-zA-Z0-9][a-zA-Z0-9-_]{0,61}[a-zA-Z0-9]{0,1}\\.(xn--)?([a-zA-Z0-9\\-]{1,61}|[a-zA-Z0-9-]{1,30}\\.[a-zA-Z]{2,}))|(localhost)|((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4})(:\\d+)?\$");

List<Tournament> tournamentList = <Tournament>[
  if (kDebugMode) Tournament("2022cc", "Chezy 2022 (debug)"),
  Tournament("2023week0", "2023 Week 0"),
  Tournament("2023cafr", "Fresno"),
  Tournament("2023camb", "Monterey"),
];

// Picklists

final List<PicklistWeight> picklistWeights = [
  PicklistWeight("totalPoints", "Total Points"),
  PicklistWeight("autoPoints", "Auto Points"),
  PicklistWeight("teleopPoints", "Teleop Points"),
  PicklistWeight("driverAbility", "Driver Ability"),
  PicklistWeight("climbResult", "Climb Result"),
  PicklistWeight("autoClimb", "Auto Climb"),
  PicklistWeight("defenseEffectiveness", "Defense Effectiveness"),
  PicklistWeight("contactDefenseTime", "Contact Defense Time"),
  PicklistWeight("campingDefenseTime", "Camping Defense Time"),
  PicklistWeight("totalDefensiveTime", "Total Defensive Time"),
  PicklistWeight("totalFuelThroughput", "Total Fuel Throughput"),
  PicklistWeight("totalFuelFed", "Total Fuel Fed"),
  PicklistWeight("feedingRate", "Feeding Rate"),
  PicklistWeight("scoringRate", "Scoring Rate"),
  PicklistWeight(
      "estimatedSuccessfulFuelRate", "Estimated Successful Fuel Rate"),
  PicklistWeight("estimatedTotalFuelScored", "Estimated Total Fuel Scored"),
];

List<ConfiguredPicklist> defaultPicklists = <ConfiguredPicklist>[
  ConfiguredPicklist.autoUuid(
    "Average total",
    picklistWeights
        .map((weight) => PicklistWeight(weight.path, weight.localizedName,
            value: weight.path == 'totalPoints' ? 1 : 0))
        .toList(),
  ),
];

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

const auth0Domain = 'lovat.us.auth0.com';

final auth0 = Auth0(auth0Domain, "PaUUK4Sjmcdy5oueW7geI2rgMfuWd1G4");
final auth0Web = Auth0Web(auth0Domain, "FR7SUG9t0wXb5ZVo51G0ewnsK7PPSyJ9");

extension StringExtension on String {
  String get hyphenated => replaceAll(" ", "-");
}
