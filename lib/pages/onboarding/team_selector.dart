import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamSelectorArgs {
  const TeamSelectorArgs({
    required this.isOnboarding,
  });

  final bool isOnboarding;
}

class TeamSelectorPage extends StatefulWidget {
  const TeamSelectorPage({super.key});

  @override
  State<TeamSelectorPage> createState() => _TeamSelectorPageState();
}

class _TeamSelectorPageState extends State<TeamSelectorPage> {
  String teamString = "";

  @override
  Widget build(BuildContext context) {
    NavigatorState navigator = Navigator.of(context);

    final TeamSelectorArgs args =
        ModalRoute.of(context)!.settings.arguments as TeamSelectorArgs;

    return Scaffold(
      appBar:
          AppBar(title: Text(args.isOnboarding ? "Welcome" : "Welcome Back")),
      body: ScrollablePageBody(
        children: [
          Text(
            "I am on...",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) {
              setState(() {
                teamString = value;
              });
            },
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(filled: true, label: Text("Team Number")),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: int.tryParse(teamString) == null
                    ? null
                    : (() async {
                        final SharedPreferences prefs =
                            await SharedPreferences.getInstance();

                        final teamNumber = int.parse(teamString);

                        await prefs.setInt("team", teamNumber);

                        if (args.isOnboarding) {
                          if (teamNumber == 8033) {
                            navigator.pushNamed('/role_selector');
                          } else {
                            await prefs.setString('role', 'analyst');
                            navigator.pushNamed("/server_authority_setup");
                          }
                        } else {
                          navigator.pushNamed('/match_schedule');
                        }
                      }),
                child: const Text("Next"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
