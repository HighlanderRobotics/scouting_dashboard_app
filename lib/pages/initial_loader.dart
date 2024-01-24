import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/pages/onboarding/onboarding_page.dart';
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
      prefs.setStringList(
        'picklists',
        defaultPicklists.map((e) => e.toJSON()).toList(),
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

    navigator.pushReplacementNamed('/match_schedule');
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
