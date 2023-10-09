import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/flags.dart';
import 'package:scouting_dashboard_app/pages/onboarding/more_info_prompt.dart';
import 'package:scouting_dashboard_app/pages/onboarding/team_selector.dart';
import 'package:scouting_dashboard_app/pages/onboarding/username_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class InitialLoaderPage extends StatefulWidget {
  const InitialLoaderPage({super.key});

  @override
  State<InitialLoaderPage> createState() => _InitialLoaderPageState();
}

class _InitialLoaderPageState extends State<InitialLoaderPage> {
  Future<void> load(NavigatorState navigator) async {
    // if (kDebugMode) {
    //   Map<String, Object> values = <String, Object>{
    //     'onboardingCompleted': false,
    //   };
    //   SharedPreferences.setMockInitialValues(values);
    // }

    final prefs = await SharedPreferences.getInstance();

    bool onboardingCompleted = false;

    if (prefs.getBool("onboardingCompleted") == true) {
      onboardingCompleted = true;
    }

    if (prefs.getString("tournament_localized") == null) {
      onboardingCompleted = false;
    }

    if (prefs.getStringList('picklists') == null) {
      await prefs.setStringList(
          'picklists', defaultPicklists.map((e) => e.toJSON()).toList());
    }

    if (prefs.getString('role') == 'team_analyst') {
      await prefs.setString('role', 'analyst');
    }

    if (prefs.getString('serverAuthority') == null) {
      await prefs.setString('serverAuthority', '157.131.22.135:25565');
    }

    if (prefs.getStringList('picklist_flags') == null) {
      await prefs.setStringList(
        'picklist_flags',
        defaultPicklistFlags.map((e) => jsonEncode(e.toJson())).toList(),
      );
    }

    if (prefs.getString('team_lookup_flag') == null) {
      await prefs.setString(
        'team_lookup_flag',
        jsonEncode(defaultTeamLookupFlag.toJson()),
      );
    }

    if (onboardingCompleted) {
      final teamIsSet = prefs.getInt('team') != null;
      final usernameIsSet = prefs.getString('username') != null;

      if (!teamIsSet) {
        navigator.pushNamedAndRemoveUntil(
          "/more_info_prompt",
          (route) => false,
          arguments: MoreInfoArgs(onContinue: () {
            navigator.pushNamed(
              "/team_selector",
              arguments: const TeamSelectorArgs(isOnboarding: false),
            );
          }),
        );
      } else if (!usernameIsSet) {
        navigator.pushNamedAndRemoveUntil(
          "/more_info_prompt",
          (route) => false,
          arguments: MoreInfoArgs(onContinue: () {
            navigator.pushNamed(
              "/username_selector",
              arguments: const UsernameSelectorArgs(isOnboarding: false),
            );
          }),
        );
      } else {
        navigator.pushNamedAndRemoveUntil("/match_schedule", (route) => false);
      }
    } else {
      navigator.pushNamedAndRemoveUntil(
        "/team_selector",
        (route) => false,
        arguments: const TeamSelectorArgs(
          isOnboarding: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    load(Navigator.of(context));

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
