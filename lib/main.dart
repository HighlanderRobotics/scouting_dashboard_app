import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/pages/initial_loader.dart';
import 'package:scouting_dashboard_app/pages/onboarding/role_selector.dart';
import 'package:scouting_dashboard_app/pages/onboarding/server_authority_selector.dart';
import 'package:scouting_dashboard_app/pages/onboarding/setup_code_scanner.dart';
import 'package:scouting_dashboard_app/pages/onboarding/tournament_selector.dart';
import 'package:scouting_dashboard_app/pages/match_schedule.dart';
import 'package:scouting_dashboard_app/pages/score_predictor.dart';
import 'package:scouting_dashboard_app/pages/scout_schedule/edit_scout_schedule.dart';
import 'package:scouting_dashboard_app/pages/settings.dart';
import 'package:scouting_dashboard_app/pages/team_lookup.dart';
import 'package:scouting_dashboard_app/pages/team_lookup_details.dart';

void main() async {
  runApp(MaterialApp(
    initialRoute: "/loading",
    routes: {
      '/loading': (context) => InitialLoader(),
      '/match_schedule': (context) => Schedule(),
      '/team_lookup': (context) => TeamLookup(),
      '/team_lookup_details': (context) => TeamLookupDetails(),
      '/score_predictor': (context) => ScorePredictor(),
      '/role_selector': (context) => RoleSelector(),
      '/tournament_selector': (context) => TournamentSelector(),
      '/server_authority_setup': (context) => ServerAuthoritySetup(),
      '/setup_code_scanner': (context) => SetupCodeScanner(),
      '/settings': (context) => Settings(),
      '/edit_scout_schedule': (context) => EditScoutSchedule(),
    },
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
    ),
  ));
}
