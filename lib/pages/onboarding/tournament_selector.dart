import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/tournament_key_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TournamentSelectorPage extends StatefulWidget {
  const TournamentSelectorPage({super.key});

  @override
  State<TournamentSelectorPage> createState() => _TournamentSelectorPageState();
}

class _TournamentSelectorPageState extends State<TournamentSelectorPage> {
  Tournament? selectedTournament;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tournament")),
      body: ScrollablePageBody(children: [
        Text(
          "I am at...",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        TournamentKeyPicker(
            onChanged: (value) {
              setState(() {
                selectedTournament = value;
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              label: Text("Tournament"),
            )),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(width: 10),
            FilledButton(
              onPressed: selectedTournament == null
                  ? null
                  : () async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();

                      await prefs.setString(
                          "tournament", selectedTournament!.key);
                      await prefs.setString("tournament_localized",
                          selectedTournament!.localized);

                      await prefs.setBool("onboardingCompleted", true);

                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          "/match_schedule", (route) => false);
                    },
              child: const Text("Finish"),
            ),
          ],
        ),
      ]),
    );
  }
}
