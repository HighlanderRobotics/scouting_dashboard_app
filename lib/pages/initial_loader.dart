import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/flags.dart';
import 'package:scouting_dashboard_app/pages/onboarding/onboarding_page.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitialLoaderPage extends StatefulWidget {
  const InitialLoaderPage({super.key});

  @override
  State<InitialLoaderPage> createState() => _InitialLoaderPageState();
}

class _InitialLoaderPageState extends State<InitialLoaderPage> {
  Future<void> load(NavigatorState navigator) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();

    // Set default picklists if they don't exist
    if (!prefs.containsKey('picklists')) {
      await prefs.setStringList(
        'picklists',
        defaultPicklists.map((e) => e.toJSON()).toList(),
      );
    }

    // Set default picklist flags if they don't exist
    if (!prefs.containsKey('picklist_flags')) {
      await prefs.setStringList('picklist_flags', []);
    }

    // Remove picklist flags that are no longer valid
    final picklistFlags = prefs.getStringList('picklist_flags')!;

    final validPicklistFlags = picklistFlags.where((e) {
      final flag = FlagConfiguration.fromJson(jsonDecode(e));
      return flags.any((f) => f.path == flag.type.path);
    }).toList();

    await prefs.setStringList('picklist_flags', validPicklistFlags);

    // Set default team lookup flag if it doesn't exist
    if (!prefs.containsKey('team_lookup_flag') ||
        !flags.any((e) => (FlagConfiguration.fromJson(
              jsonDecode(
                prefs.getString('team_lookup_flag')!,
              ),
            ).type.path ==
            e.path))) {
      await prefs.setString(
        'team_lookup_flag',
        jsonEncode(
          FlagConfiguration(flags.first, flags.first.defaultHue).toJson(),
        ),
      );
    }

    final onboardingVersion = prefs.getInt('onboardingVersion');

    if (onboardingVersion == null || onboardingVersion < 1) {
      navigator.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              child,
          transitionDuration: Duration.zero,
        ),
      );
      return;
    }

    final tournament = await Tournament.getCurrent();

    if (tournament == null) {
      navigator.pushReplacementNamed('/team_lookup');
      return;
    } else {
      navigator.pushReplacementNamed('/match_schedule');
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
