import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: const ScrollablePageBody(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40),
              ResetAppButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class ResetAppButton extends StatelessWidget {
  const ResetAppButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text("Delete configuration?"),
                  content: const Text(
                      "If you continue, you will erase all the data this app has saved and reset it to how it came when you first installed it."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();

                        await prefs.clear();
                        await auth0.credentialsManager.clearCredentials();

                        Navigator.of(context).pushNamedAndRemoveUntil(
                            "/loading", (route) => false);
                      },
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all(0),
                        backgroundColor: MaterialStateProperty.resolveWith(
                            (states) => Theme.of(context).colorScheme.error),
                        foregroundColor: MaterialStateProperty.resolveWith(
                            (states) => Theme.of(context).colorScheme.onError),
                      ),
                      child: const Text("Delete"),
                    ),
                  ],
                ));
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith(
            (states) => Theme.of(context).colorScheme.error),
        foregroundColor: MaterialStateProperty.resolveWith(
            (states) => Theme.of(context).colorScheme.onError),
      ),
      child: const Text("Reset app and delete settings"),
    );
  }
}
