import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleSelector extends StatefulWidget {
  const RoleSelector({super.key});

  @override
  State<RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector> {
  String role = "analyst";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome")),
      body: ScrollablePageBody(
        children: [
          Text(
            "I am a...",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text("Analyst"),
            leading: Icon(Icons.insights,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            trailing: Radio(
                value: "analyst",
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: role,
                onChanged: ((value) {
                  setState(() {
                    if (value == null) return;
                    role = value;
                  });
                })),
          ),
          ListTile(
            title: const Text("Scouting Lead"),
            leading: Icon(Icons.supervisor_account,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            trailing: Radio(
                value: "scouting_lead",
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: role,
                onChanged: ((value) {
                  setState(() {
                    if (value == null) return;
                    role = value;
                  });
                })),
          ),
          const SizedBox(height: 20),
          const Text(
              "Both get access to processed scouting data. Scouting leads get additional tools for modifying the scout schedule and scanning QR codes."),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: (() async {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();

                  await prefs.setString("role", role);

                  Navigator.of(context).pushNamed("/server_authority_setup");
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
