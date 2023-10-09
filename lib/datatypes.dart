import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Tournament {
  Tournament(this.key, this.localized);

  String key;
  String localized;

  @override
  String toString() => localized;
}

Future<ScoutSchedule> getScoutSchedule() async {
  final json = utf8.decode((await http.get(Uri.http(
          (await getServerAuthority())!, '/API/manager/getScoutersSchedule')))
      .bodyBytes);

  return ScoutSchedule.fromJSON(json);
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

enum Penalty {
  none,
  yellowCard,
  redCard,
}

extension PenaltyExtension on Penalty {
  String get localizedDescription {
    switch (this) {
      case Penalty.none:
        return "None";
      case Penalty.yellowCard:
        return "Yellow card";
      case Penalty.redCard:
        return "Red card";
      default:
        return "Unknown";
    }
  }

  Color get color {
    switch (this) {
      case Penalty.none:
        return Colors.green[700]!;
      case Penalty.yellowCard:
        return Color.fromARGB(255, 230, 251, 45);
      case Penalty.redCard:
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}

Future<Map<String, String?>> getScoutedStatuses() async {
  final List<Map<String, dynamic>> isScoutedResponse = (jsonDecode(utf8.decode(
          (await http.get(Uri.http(
                  (await getServerAuthority())!, '/API/manager/isScouted', {
    'tournamentKey':
        (await SharedPreferences.getInstance()).getString('tournament'),
  })))
              .bodyBytes)) as List<dynamic>)
      .cast();

  Map<String, String?> isScoutedElegante = {};

  for (var response in isScoutedResponse) {
    isScoutedElegante[response['key']] = response['name'];
  }

  return isScoutedElegante;
}

class ScoringMethod {
  const ScoringMethod(this.path, this.localizedName);

  final String path;
  final String localizedName;
}

extension ListSpaceBetweenExtension on List<Widget> {
  List<Widget> withSpaceBetween({double? width, double? height}) => [
        for (int i = 0; i < this.length; i++) ...[
          if (i > 0) SizedBox(width: width, height: height),
          this[i],
        ],
      ];
}

String minutesAndSeconds(Duration duration) =>
    "${duration.inMinutes}:${(duration.inSeconds.remainder(60).toString().padLeft(2, '0'))}";

extension NumListExtension on List<num> {
  num sum() => isEmpty ? 0 : reduce((value, element) => value + element);

  num average() => sum() / length;
}
