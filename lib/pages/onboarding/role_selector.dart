import 'package:flutter/material.dart';
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "I am a...",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text("Analyst"),
              leading: const Icon(Icons.insights),
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
              leading: const Icon(Icons.supervisor_account),
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
            ElevatedButton(
              onPressed: (() async {
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();

                await prefs.setString("role", role);

                Navigator.of(context).pushNamed("/tournament_selector");
              }),
              child: const Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}
