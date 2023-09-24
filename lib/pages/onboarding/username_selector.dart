import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsernameSelectorArgs {
  const UsernameSelectorArgs({
    required this.isOnboarding,
  });

  final bool isOnboarding;
}

class UsernameSelectorPage extends StatefulWidget {
  const UsernameSelectorPage({super.key});

  @override
  State<UsernameSelectorPage> createState() => _UsernameSelectorPageState();
}

class _UsernameSelectorPageState extends State<UsernameSelectorPage> {
  String username = "";

  @override
  Widget build(BuildContext context) {
    NavigatorState navigator = Navigator.of(context);

    final UsernameSelectorArgs args =
        ModalRoute.of(context)!.settings.arguments as UsernameSelectorArgs;

    return Scaffold(
      appBar:
          AppBar(title: Text(args.isOnboarding ? "Welcome" : "Welcome Back")),
      body: ScrollablePageBody(
        children: [
          Text(
            "Choose a name",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            autofocus: true,
            onChanged: (value) {
              setState(() {
                username = value;
              });
            },
            decoration:
                const InputDecoration(filled: true, label: Text("Username")),
            maxLength: 50,
          ),
          const SizedBox(height: 20),
          const Text(
              "Other members of your team will use this to identify you."),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: username.isEmpty
                    ? null
                    : (() async {
                        final SharedPreferences prefs =
                            await SharedPreferences.getInstance();

                        await prefs.setString("username", username);

                        // Set picklists to use this name
                        final picklists = await getPicklists();
                        final newPicklists = picklists.map((picklist) {
                          picklist.author = username;
                          return picklist;
                        }).toList();

                        await setPicklists(newPicklists);

                        if (args.isOnboarding) {
                          navigator.pushNamed("/tournament_selector");
                        } else {
                          navigator.pushNamedAndRemoveUntil(
                              '/match_schedule', (route) => false);
                        }
                      }),
                child: Text(args.isOnboarding ? "Next" : "Done"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
