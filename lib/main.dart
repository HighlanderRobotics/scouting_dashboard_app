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
import 'package:scouting_dashboard_app/pages/display_qr_codes.dart';
import 'package:scouting_dashboard_app/pages/scouters.dart';
import 'package:scouting_dashboard_app/pages/set_api_url.dart';
import 'package:scouting_dashboard_app/pages/settings.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/edit_team_lookup_flag.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup_details.dart';
import 'package:scouting_dashboard_app/pages/team_per_match.dart';

void main() async {
  runApp(MaterialApp(
    initialRoute: "/loading",
    routes: {
      '/loading': (context) => const InitialLoaderPage(),
      '/preview_over': (context) => const PreviewOverPage(),
      '/match_schedule': (context) => const MatchSchedulePage(),
      '/raw_scout_report': (context) => RawScoutReportPage(
            uuid: (ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>)['uuid'],
            teamNumber: (ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>)['teamNumber'],
            matchIdentity: (ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>)['matchIdentity'],
            scoutName: (ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>)['scoutName'],
            onDeleted: (ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>)['onDeleted'],
          ),
      '/team_per_match': (context) => const TeamPerMatchPage(),
      '/team_lookup': (context) => const TeamLookupPage(),
      '/edit_team_lookup_flag': (context) => const EditTeamLookupFlagPage(),
      '/team_lookup_details': (context) => const TeamLookupDetailsPage(),
      '/display_qr_codes': (context) => const DisplayQRCodesPage(),
      '/edit_scout_schedule': (context) => const EditScoutSchedulePage(),
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
      '/view_picklist_weights': (context) => ViewPicklistWeightsPage(
            picklistMeta: (ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>)['picklistMeta'],
          ),
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
      '/scouters': (context) => const ScoutersPage(),
      // '/set-api-url': (context) => const SetAPIUrlPage(),
    },
    onGenerateRoute: (settings) {
      if (settings.name == null) return null;

      if (settings.name!.startsWith('/set-url')) {
        // Parse the URL query parameters
        final Map<String, String> queryParameters = Map.fromEntries(settings
            .name!
            .split('?')[1]
            .split('&')
            .map((e) => e.split('='))
            .map((e) => MapEntry(e[0], e[1]))
            .map((e) => MapEntry(
                Uri.decodeComponent(e.key), Uri.decodeComponent(e.value))));

        final String? apiBaseUrl = queryParameters['u'];

        if (apiBaseUrl == null) {
          return null;
        }

        return MaterialPageRoute<void>(
          builder: (context) => SetAPIUrlPage(apiBaseUrl: apiBaseUrl),
        );
      }

      return null;
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
