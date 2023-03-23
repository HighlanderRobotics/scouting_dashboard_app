import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/pages/alliance.dart';
import 'package:scouting_dashboard_app/pages/initial_loader.dart';
import 'package:scouting_dashboard_app/pages/match_predictor_opener.dart';
import 'package:scouting_dashboard_app/pages/my_alliance.dart';
import 'package:scouting_dashboard_app/pages/onboarding/role_selector.dart';
import 'package:scouting_dashboard_app/pages/onboarding/server_authority_selector.dart';
import 'package:scouting_dashboard_app/pages/onboarding/setup_code_scanner.dart';
import 'package:scouting_dashboard_app/pages/onboarding/tournament_selector.dart';
import 'package:scouting_dashboard_app/pages/match_schedule.dart';
import 'package:scouting_dashboard_app/pages/picklist/edit_picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/new_picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_team_breakdown.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklists.dart';
import 'package:scouting_dashboard_app/pages/scan_qr_codes.dart';
import 'package:scouting_dashboard_app/pages/match_predictor.dart';
import 'package:scouting_dashboard_app/pages/scout_schedule/edit_scout_schedule.dart';
import 'package:scouting_dashboard_app/pages/scout_schedule/new_scout_shift.dart';
import 'package:scouting_dashboard_app/pages/scout_schedule/scout_schedule_qr.dart';
import 'package:scouting_dashboard_app/pages/settings.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup_details.dart';

import 'pages/scout_schedule/edit_scout_shift.dart';

void main() async {
  runApp(MaterialApp(
    initialRoute: "/loading",
    routes: {
      '/loading': (context) => const InitialLoader(),
      '/match_schedule': (context) => const Schedule(),
      '/team_lookup': (context) => const TeamLookup(),
      '/team_lookup_details': (context) => const TeamLookupDetails(),
      '/match_predictor_opener': (context) => const MatchPredictorOpenerPage(),
      '/match_predictor': (context) => const MatchPredictor(),
      '/role_selector': (context) => const RoleSelector(),
      '/tournament_selector': (context) => const TournamentSelector(),
      '/server_authority_setup': (context) => const ServerAuthoritySetup(),
      '/setup_code_scanner': (context) => const SetupCodeScanner(),
      '/settings': (context) => const Settings(),
      '/edit_scout_schedule': (context) => const EditScoutSchedule(),
      '/edit_scout_shift': (context) => const EditScoutShift(),
      '/new_scout_shift': (context) => const NewScoutShift(),
      '/scout_schedule_qr': (context) => const ScoutScheduleQR(),
      '/scan_qr_codes': (context) => const ScanQRCodesPage(),
      '/picklists': (context) => const PicklistsPage(),
      '/picklist': (context) => const PicklistPage(),
      '/new_picklist': (context) => const NewPicklistPage(),
      '/edit_picklist': (context) => const EditPicklistPage(),
      '/picklist_team_breakdown': (context) =>
          const PicklistTeamBreakdownPage(),
      '/alliance': (context) => const AlliancePage(),
      '/my_alliance': (context) => const MyAlliancePage(),
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
