import 'dart:convert';

import 'package:scouting_dashboard_app/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Tournament {
  Tournament(this.key, this.localized);

  String key;
  String localized;

  @override
  String toString() => localized;
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
}

class ScoutSchedule {
  ScoutSchedule({
    required this.version,
    required this.shifts,
  });

  int version;
  List<ScoutingShift> shifts;
}

Future<ScoutSchedule> getScoutSchedule() async {
  final json = jsonDecode(utf8.decode((await http.get(Uri.http(
          (await getServerAuthority())!, '/API/manager/getScoutersSchedule')))
      .bodyBytes));

  return ScoutSchedule(
    version: json['version'],
    shifts: (json['matches']
            as List) // TODO: Change matches to shifts when Barry changes it
        .map((shift) => ScoutingShift(
              start: shift['start'],
              end: shift['end'],
              scouts:
                  (shift['scouts'] as List).map((e) => e.toString()).toList(),
            ))
        .toList(),
  );
}
