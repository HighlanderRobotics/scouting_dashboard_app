import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/pages/alliance.dart';
import 'package:scouting_dashboard_app/pages/auto_path_selector.dart';
import 'package:scouting_dashboard_app/pages/initial_loader.dart';
import 'package:scouting_dashboard_app/pages/match_predictor_opener.dart';
import 'package:scouting_dashboard_app/pages/match_suggestions.dart';
import 'package:scouting_dashboard_app/pages/match_suggestions_opener.dart';
import 'package:scouting_dashboard_app/pages/my_alliance.dart';
import 'package:scouting_dashboard_app/pages/match_schedule.dart';
import 'package:scouting_dashboard_app/pages/onboarding/onboarding_page.dart';
import 'package:scouting_dashboard_app/pages/picklist/edit_picklist_flags.dart';
import 'package:scouting_dashboard_app/pages/picklist/edit_picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/mutable_picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/new_picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/picked_teams.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/shared_picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_team_breakdown.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklists.dart';
import 'package:scouting_dashboard_app/pages/picklist/view_picklist_weights.dart';
import 'package:scouting_dashboard_app/pages/preview_over.dart';
import 'package:scouting_dashboard_app/pages/raw_scout_report.dart';
import 'package:scouting_dashboard_app/pages/scan_qr_codes.dart';
import 'package:scouting_dashboard_app/pages/match_predictor.dart';
import 'package:scouting_dashboard_app/pages/scout_schedule/edit_scout_schedule.dart';
import 'package:scouting_dashboard_app/pages/scout_schedule/new_scout_shift.dart';
import 'package:scouting_dashboard_app/pages/display_qr_codes.dart';
import 'package:scouting_dashboard_app/pages/settings.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/edit_team_lookup_flag.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup_breakdown_details.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup_details.dart';
import 'package:scouting_dashboard_app/pages/team_per_match.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';

import 'pages/scout_schedule/edit_scout_shift.dart';

void main() async {
  runApp(MaterialApp(
    initialRoute: "/loading",
    routes: {
      '/loading': (context) => const InitialLoaderPage(),
      '/preview_over': (context) => const PreviewOverPage(),
      '/match_schedule': (context) => const MatchSchedulePage(),
      '/raw_scout_report': (context) => const RawScoutReportPage(),
      '/team_per_match': (context) => const TeamPerMatchPage(),
      '/team_lookup': (context) => const TeamLookupPage(),
      '/edit_team_lookup_flag': (context) => const EditTeamLookupFlagPage(),
      '/team_lookup_details': (context) => const TeamLookupDetailsPage(),
      '/team_lookup_breakdown_details': (context) =>
          const TeamLookupBreakdownDetailsPage(),
      '/display_qr_codes': (context) => const DisplayQRCodesPage(),
      '/edit_scout_schedule': (context) => const EditScoutSchedulePage(),
      '/edit_scout_shift': (context) => const EditScoutShiftPage(),
      '/new_scout_shift': (context) => const NewScoutShiftPage(),
      '/match_predictor': (context) => const MatchPredictorPage(),
      '/match_predictor_opener': (context) => const MatchPredictorOpenerPage(),
      '/match_suggestions': (context) => const MatchSuggestionsPage(),
      '/match_suggestions_opener': (context) =>
          const MatchSuggestionsOpenerPage(),
      '/alliance': (context) => const AlliancePage(),
      '/auto_path_selector': (context) => const AutoPathSelectorPage(),
      '/my_alliance': (context) => const AllianceOpenerPage(),
      '/settings': (context) => const SettingsPage(),
      '/scan_qr_codes': (context) => const ScoutReportScannerPage(),
      '/picklists': (context) => const PicklistsPage(),
      '/picklist': (context) => const MyPicklistPage(),
      '/edit_picklist_flags': (context) => const EditPicklistFlagsPage(),
      '/new_picklist': (context) => const NewPicklistPage(),
      '/edit_picklist': (context) => const EditPicklistPage(),
      '/picklist_team_breakdown': (context) =>
          const PicklistTeamBreakdownPage(),
      '/shared_picklist': (context) => const SharedPicklistPage(),
      '/view_picklist_weights': (context) => const ViewPicklistWeightsPage(),
      '/mutable_picklist': (context) => const MutablePicklistPage(),
      '/picked_teams': (context) => const PickedTeamsPage(),
      '/specific_source_teams': (context) => SpecificSourceTeamPage(
            onSubmit: (ModalRoute.of(context)!.settings.arguments
                    as SpecificSourceTeamsArguments)
                .onSubmit,
            initialTeams: (ModalRoute.of(context)!.settings.arguments
                    as SpecificSourceTeamsArguments)
                .initialTeams,
            submitText: (ModalRoute.of(context)!.settings.arguments
                    as SpecificSourceTeamsArguments)
                .submitText,
          ),
    },
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
    ),
  ));
}
