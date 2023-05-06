import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitialLoaderPage extends StatefulWidget {
  const InitialLoaderPage({super.key});

  @override
  State<InitialLoaderPage> createState() => _InitialLoaderPageState();
}

class _InitialLoaderPageState extends State<InitialLoaderPage> {
  void load() async {
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

    if (onboardingCompleted) {
      // ignore: unnecessary_this
      Navigator.of(this.context)
          .pushNamedAndRemoveUntil("/match_schedule", (route) => false);
    } else {
      // ignore: unnecessary_this
      Navigator.of(this.context)
          .pushNamedAndRemoveUntil("/role_selector", (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    load();

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
