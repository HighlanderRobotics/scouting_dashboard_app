import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tournament {
  Tournament(this.key, this.localized);

  String key;
  String localized;

  @override
  String toString() => localized;

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      json['key'],
      "${(json['date'] as String).split('-')[0]} ${json['name']}",
    );
  }

  Future<void> storeAsCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tournament', key);
    await prefs.setString('tournament_localized', localized);
  }

  static Future<Tournament?> getCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('tournament');
    final name = prefs.getString('tournament_localized');

    if (key == null || name == null) {
      return null;
    }

    return Tournament(key, name);
  }

  static Future<void> clearCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tournament');
    await prefs.remove('tournament_localized');
  }

  Future<List<MatchScheduleMatch>> getMatches() async {
    return await lovatAPI.getMatches(key);
  }

  Future<List<Team>> getTeams() async {
    return await lovatAPI.getTeamsAtTournament(key);
  }
}

Future<List<String>> getScoutNames() async {
  return ((jsonDecode(utf8.decode((await http.get(Uri.http(
              (await getServerAuthority())!, '/API/manager/getScouters')))
          .bodyBytes))) as List<dynamic>)
      .map((e) => e.toString())
      .toList();
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
        return const Color.fromARGB(255, 230, 251, 45);
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
        for (int i = 0; i < length; i++) ...[
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
