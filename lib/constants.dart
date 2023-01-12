import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:shared_preferences/shared_preferences.dart';

RegExp validServerAuthority = RegExp(
    "^((((?!-))(xn--)?[a-zA-Z0-9][a-zA-Z0-9-_]{0,61}[a-zA-Z0-9]{0,1}\\.(xn--)?([a-zA-Z0-9\\-]{1,61}|[a-zA-Z0-9-]{1,30}\\.[a-zA-Z]{2,}))|(localhost))(:\\d+)?\$");

List<Tournament> tournamentList = <Tournament>[
  Tournament("2023cafr", "Central Valley Regional 2023"),
  Tournament("2023camb", "Monterey Bay Regional 2023"),
  Tournament("2023cmptx", "Houston World 2023"),
  Tournament("2023cc", "Chezy Champs 2023"),
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
