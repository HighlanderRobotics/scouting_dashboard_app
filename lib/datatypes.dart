import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_matches.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_teams_at_tournament.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tournament {
  Tournament(this.key, this.localized);

  String key;
  String localized;

  static Tournament? _currentCache;

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
    _currentCache = this;
  }

  static Tournament? get currentSync => _currentCache;

  static Future<Tournament?> getCurrent() async {
    if (_currentCache != null) return _currentCache;

    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('tournament');
    final name = prefs.getString('tournament_localized');

    if (key == null || name == null) {
      return null;
    }

    _currentCache = Tournament(key, name);
    return _currentCache;
  }

  static Future<void> clearCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tournament');
    await prefs.remove('tournament_localized');
    _currentCache = null;
  }

  Future<List<MatchScheduleMatch>> getMatches() async {
    return await lovatAPI.getMatches(key);
  }

  Future<List<Team>> getTeams() async {
    return await lovatAPI.getTeamsAtTournament(key);
  }
}

extension ListSpaceBetweenExtension on List<Widget> {
  List<Widget> withWidgetBetween(Widget separator) => [
        for (int i = 0; i < length; i++) ...[
          if (i > 0) separator,
          this[i],
        ],
      ];

  List<Widget> withSpaceBetween({double? width, double? height}) =>
      withWidgetBetween(SizedBox(width: width, height: height));
}

extension NumListExtension on List<num> {
  num sum() => isEmpty ? 0 : reduce((value, element) => value + element);

  num average() => sum() / length;
}
