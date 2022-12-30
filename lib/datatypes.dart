import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:http/http.dart' as http;

class Tournament {
  Tournament(this.key, this.localized);

  String key;
  String localized;

  @override
  String toString() => localized;
}

class ScoutSchedule {
  ScoutSchedule({
    required this.version,
    required this.shifts,
  });

  int version;
  List<ScoutingShift> shifts;

  ScoutSchedule copy() {
    return ScoutSchedule(
      version: version,
      shifts: shifts.map((s) => s.copy()).toList(),
    );
  }

  List<String> getScoutsForMatch(int match) {
    List<String> scouts = [];
    for (ScoutingShift shift in shifts) {
      if (shift.start <= match && match <= shift.end) {
        scouts.addAll(shift.scouts);
      }
    }
    return scouts;
  }

  bool shiftsDoNotOverlap() {
    for (int i = 0; i < shifts.length - 1; i++) {
      for (int j = i + 1; j < shifts.length; j++) {
        if (shifts[i].end >= shifts[j].start &&
            shifts[i].start <= shifts[j].end) {
          return false;
        }
      }
    }
    return true;
  }

  bool noGapsBetweenShifts() {
    for (int i = 0; i < shifts.length - 1; i++) {
      if (shifts[i].end != shifts[i + 1].start - 1) {
        return false;
      }
    }
    return true;
  }

  bool allMatchNumbersPositive() {
    for (ScoutingShift shift in shifts) {
      if (shift.start < 0 || shift.end < 0) {
        return false;
      }
    }
    return true;
  }

  bool shiftsHaveValidRanges() {
    for (ScoutingShift shift in shifts) {
      if (shift.end < shift.start) {
        return false;
      }
    }
    return true;
  }

  bool noEmptyScoutNames() {
    for (ScoutingShift shift in shifts) {
      if (shift.scouts.any((s) => s.trim().isEmpty)) {
        return false;
      }
    }
    return true;
  }

  String? validate() {
    if (!shiftsDoNotOverlap()) return 'Some shifts overlap.';
    if (!noGapsBetweenShifts()) return 'Some shifts have gaps between them.';
    if (!allMatchNumbersPositive()) return 'Some match numbers are negative.';
    if (!shiftsHaveValidRanges()) {
      return 'Some shifts don\'t have valid ranges.';
    }
    if (!noEmptyScoutNames()) {
      return 'Some scout names are empty or contain only whitespace.';
    }

    // If it's valid, return null.
    return null;
  }

  String toJSON() {
    final shiftsMap = shifts
        .map((shift) => {
              'start': shift.start,
              'end': shift.end,
              'scouts': shift.scouts,
            })
        .toList();

    print(jsonEncode({
      'version': version,
      'shifts': shiftsMap,
    }));

    return jsonEncode({
      'version': version,
      'shifts': shiftsMap,
    });
  }

  Future<void> upload() async {
    http.post(
      Uri.http(
          (await getServerAuthority())!, '/API/manager/updateScoutersSchedule'),
      body: toJSON(),
      headers: {
        'type': 'application/json',
      },
    );
  }

  Future<void> save() async {
    version++;
    await upload();
  }
}

class ScoutingShift {
  ScoutingShift({
    required this.start,
    required this.end,
    required this.scouts,
  });

  int start;
  int end;
  List<String> scouts;

  ScoutingShift copy() {
    return ScoutingShift(
      start: start,
      end: end,
      scouts: List.from(scouts),
    );
  }
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
