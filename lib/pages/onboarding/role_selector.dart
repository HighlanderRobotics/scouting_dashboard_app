import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/correct_passwords.dart';
import 'package:scouting_dashboard_app/reusable/password_protection.dart';
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
            "I am an...",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text("Analyst"),
            leading: Icon(Icons.timeline,
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
            title: const Text("8033 Analyst"),
            leading: Icon(Icons.insights,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            trailing: Radio(
                value: "8033_analyst",
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: role,
                onChanged: ((value) {
                  passwordProtected(context, teamAnalystCorrectPassword, () {
                    setState(() {
                      if (value == null) return;
                      role = value;
                    });
                  });
                })),
          ),
          ListTile(
            title: const Text("8033 Scouting Lead"),
            leading: Icon(Icons.supervisor_account,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            trailing: Radio(
                value: "8033_scouting_lead",
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: role,
                onChanged: ((value) {
                  passwordProtected(context, teamScoutingLeadCorrectPassword,
                      () {
                    setState(() {
                      if (value == null) return;
                      role = value;
                    });
                  });
                })),
          ),
          const SizedBox(height: 20),
          const Text(
              "If you're on another team checking out our data, use Analyst. 8033 Analysts also get access to all the data, but can publish picklists to each other and use mutable picklists. 8033 Scouting Leads can do all of this, and also can view and delete raw data, manage schedules, and edit data."),
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
