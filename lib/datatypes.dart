import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:http/http.dart' as http;

class Tournament {
  Tournament(this.key, this.localized);

  String key;
  String localized;

  @override
  String toString() => localized;
}

Future<ScoutSchedule> getScoutSchedule() async {
  final json = jsonDecode(utf8.decode((await http.get(Uri.http(
          (await getServerAuthority())!, '/API/manager/getScoutersSchedule')))
      .bodyBytes));

  return ScoutSchedule(
    version: json['version'],
    shifts: (json['shifts'] as List)
        .map((shift) => ScoutingShift(
              start: shift['start'],
              end: shift['end'],
              scouts:
                  (shift['scouts'] as List).map((e) => e.toString()).toList(),
            ))
        .toList(),
  );
}

Future<List<String>> getScoutNames() async {
  return ((jsonDecode(utf8.decode((await http.get(Uri.http(
              (await getServerAuthority())!, '/API/manager/getScouters')))
          .bodyBytes))) as List<dynamic>)
      .map((e) => e.toString())
      .toList();
}

bool areShiftsEqual(ScoutingShift shift1, ScoutingShift shift2) {
  return shift1.start == shift2.start &&
      shift1.end == shift2.end &&
      listEquals(shift1.scouts, shift2.scouts);
}

bool areSchedulesEqual(ScoutSchedule schedule1, ScoutSchedule schedule2) {
  try {
    return schedule1.version == schedule2.version &&
        schedule1.shifts.every(
          (shift) => areShiftsEqual(
            shift,
            schedule2.shifts[schedule1.shifts.indexOf(shift)],
          ),
        ) &&
        schedule2.shifts.every(
          (shift) => areShiftsEqual(
            shift,
            schedule1.shifts[schedule2.shifts.indexOf(shift)],
          ),
        );
  } on RangeError {
    return false;
  }
}
