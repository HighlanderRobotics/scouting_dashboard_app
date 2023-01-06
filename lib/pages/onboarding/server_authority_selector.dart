import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants.dart';

class ServerAuthoritySetup extends StatefulWidget {
  const ServerAuthoritySetup({super.key});

  @override
  State<ServerAuthoritySetup> createState() => _ServerAuthoritySetupState();
}

class _ServerAuthoritySetupState extends State<ServerAuthoritySetup> {
  String serverAuthority = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome")),
      body: ScrollablePageBody(
        children: [
          TextField(
            decoration: const InputDecoration(
              filled: true,
              label: Text("Server Authority"),
            ),
            onChanged: (value) {
              setState(() {
                serverAuthority = value;
              });
            },
            autocorrect: false,
            keyboardType: TextInputType.url,
          ),
          if (serverAuthority.isNotEmpty &&
              !validServerAuthority.hasMatch(serverAuthority))
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                "Must be a valid domain not prefixed with \"http://\" or \"https://\"",
                style: Theme.of(context).textTheme.caption?.merge(
                      TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
              "Ask your server manager if you don't know what to put here."),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed("/setup_code_scanner");
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Use QR code"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: validServerAuthority.hasMatch(serverAuthority)
                      ? () async {
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();

                          await prefs.setString(
                              "serverAuthority", serverAuthority);

                          await prefs.setBool("onboardingCompleted", true);

                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              "/match_schedule", (route) => false);
                        }
                      : null,
                  child: const Text("Finish")),
            ],
          ),
        ],
      ),
    );
  }
}
