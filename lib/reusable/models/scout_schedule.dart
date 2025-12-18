import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScoutSchedule {
  ScoutSchedule({
    required this.hash,
    required this.shifts,
  });

  String hash;
  List<ScoutingShift> shifts;

  ScoutSchedule copy() {
    return ScoutSchedule(
      hash: hash,
      shifts: shifts.map((s) => s.copy()).toList(),
    );
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

  String? validate() {
    if (!shiftsDoNotOverlap()) return 'Some shifts overlap.';
    if (!allMatchNumbersPositive()) return 'Some match numbers are negative.';
    if (!shiftsHaveValidRanges()) {
      return 'Some shifts don\'t have valid ranges.';
    }

    // If it's valid, return null.
    return null;
  }

  factory ScoutSchedule.fromJson(Map<String, dynamic> json) {
    return ScoutSchedule(
      hash: json["hash"],
      shifts: (json["data"] as List)
          .map((shift) => ServerScoutingShift.fromJson(shift))
          .toList(),
    );
  }

  Color getVerionColor(String hash, double saturation, double lightness) {
    int sum = 0;

    for (int i = 0; i < hash.length; i++) {
      sum += hash.codeUnitAt(i);
    }

    final hue = (sum * math.e) % 360;

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }
}

class ServerScoutSchedule extends ScoutSchedule {
  ServerScoutSchedule({
    required super.hash,
    required List<ServerScoutingShift> super.shifts,
  });

  factory ServerScoutSchedule.fromJson(Map<String, dynamic> json) {
    return ServerScoutSchedule(
      hash: json["hash"],
      shifts: (json["data"] as List)
          .map((shift) => ServerScoutingShift.fromJson(shift))
          .toList(),
    );
  }

  @override
  List<ServerScoutingShift> get shifts =>
      super.shifts as List<ServerScoutingShift>;
}

class ScoutingShift {
  ScoutingShift({
    required this.start,
    required this.end,
    required this.team1,
    required this.team2,
    required this.team3,
    required this.team4,
    required this.team5,
    required this.team6,
  });

  int start;
  int end;

  List<Scout> team1;
  List<Scout> team2;
  List<Scout> team3;
  List<Scout> team4;
  List<Scout> team5;
  List<Scout> team6;

  String get allScoutsList {
    List<Scout> allScouts = [];

    allScouts.addAll(team1);
    allScouts.addAll(team2);
    allScouts.addAll(team3);
    allScouts.addAll(team4);
    allScouts.addAll(team5);
    allScouts.addAll(team6);

    return allScouts.map((s) => s.name).join(", ");
  }

  ScoutingShift copy() {
    return ScoutingShift(
      start: start,
      end: end,
      team1: team1.map((s) => s).toList(),
      team2: team2.map((s) => s).toList(),
      team3: team3.map((s) => s).toList(),
      team4: team4.map((s) => s).toList(),
      team5: team5.map((s) => s).toList(),
      team6: team6.map((s) => s).toList(),
    );
  }
}

class ServerScoutingShift extends ScoutingShift {
  ServerScoutingShift({
    required super.start,
    required super.end,
    required super.team1,
    required super.team2,
    required super.team3,
    required super.team4,
    required super.team5,
    required super.team6,
    required this.id,
  });

  String id;

  factory ServerScoutingShift.fromJson(Map<String, dynamic> json) {
    return ServerScoutingShift(
      start: json['startMatchOrdinalNumber'],
      end: json['endMatchOrdinalNumber'],
      team1: (json['team1'] as List).map((s) => Scout.fromJson(s)).toList(),
      team2: (json['team2'] as List).map((s) => Scout.fromJson(s)).toList(),
      team3: (json['team3'] as List).map((s) => Scout.fromJson(s)).toList(),
      team4: (json['team4'] as List).map((s) => Scout.fromJson(s)).toList(),
      team5: (json['team5'] as List).map((s) => Scout.fromJson(s)).toList(),
      team6: (json['team6'] as List).map((s) => Scout.fromJson(s)).toList(),
      id: json['uuid'],
    );
  }

  @override
  ServerScoutingShift copy() {
    return ServerScoutingShift(
      start: start,
      end: end,
      team1: team1.map((s) => s).toList(),
      team2: team2.map((s) => s).toList(),
      team3: team3.map((s) => s).toList(),
      team4: team4.map((s) => s).toList(),
      team5: team5.map((s) => s).toList(),
      team6: team6.map((s) => s).toList(),
      id: id,
    );
  }
}

class Scout {
  const Scout({
    required this.name,
    required this.id,
  });

  final String name;
  final String id;

  factory Scout.fromJson(Map<String, dynamic> json) {
    return Scout(
      name: json['name'],
      id: json['uuid'],
    );
  }
}
