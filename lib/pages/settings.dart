import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/correct_passwords.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/password_protection.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/tournament_key_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? initialRole;
  String? initialTournament;
  String? initialTournamentName;
  String? initialServerAuthority;
  int? initialTeamNumber;

  Future<void> setInitialValues() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      initialRole = "scouting_lead";
      initialTournament = "2022cc";
      initialTournamentName = "2022 Chezy Champs";
      initialServerAuthority = "localhost:3000";
      initialTeamNumber = 8033;
    });
  }

  @override
  void initState() {
    super.initState();

    setInitialValues();
  }

  @override
  Widget build(BuildContext context) {
    if (initialRole == null ||
        initialTournament == null ||
        initialServerAuthority == null ||
        initialTournamentName == null ||
        initialTeamNumber == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return LoadedSettings(
        initialRole: initialRole!,
        initialTournament: initialTournament!,
        initialTournamentName: initialTournamentName!,
        initialServerAuthority: initialServerAuthority!,
        initialTeamNumber: initialTeamNumber!,
      );
    }
  }
}

class LoadedSettings extends StatefulWidget {
  const LoadedSettings({
    Key? key,
    required this.initialRole,
    required this.initialTournament,
    required this.initialTournamentName,
    required this.initialServerAuthority,
    required this.initialTeamNumber,
  }) : super(key: key);

  final String initialRole;
  final String initialTournament;
  final String initialTournamentName;
  final String initialServerAuthority;
  final int initialTeamNumber;

  @override
  State<LoadedSettings> createState() => _LoadedSettingsState();
}

class _LoadedSettingsState extends State<LoadedSettings> {
  late String role = widget.initialRole;
  late String tournament = widget.initialTournament;
  late String tournamentName = widget.initialTournamentName;
  late String serverAuthority = widget.initialServerAuthority;
  late final TextEditingController _serverAuthorityController =
      TextEditingController(text: serverAuthority);
  late String teamNumber = widget.initialTeamNumber.toString();
  late final TextEditingController _teamNumberController =
      TextEditingController(text: teamNumber);

  bool getAllowSave() {
    // Check for changes
    if (role == widget.initialRole &&
        tournament == widget.initialTournament &&
        serverAuthority == widget.initialServerAuthority &&
        teamNumber == widget.initialTeamNumber.toString()) return false;

    // Validate new values
    if (!validServerAuthority.hasMatch(serverAuthority)) return false;
    if (int.tryParse(teamNumber) == null) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "Save changes",
            color: Colors.green,
            onPressed: getAllowSave()
                ? () async {
                    final prefs = await SharedPreferences.getInstance();

                    await prefs.setString("role", role);
                    await prefs.setString("tournament", tournament);
                    await prefs.setString(
                        "tournament_localized", tournamentName);
                    await prefs.setString("serverAuthority", serverAuthority);
                    await prefs.setInt("team", int.parse(teamNumber));

                    const snackBar = SnackBar(
                      content: Text("Saved changes"),
                      behavior: SnackBarBehavior.floating,
                    );

                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        "/match_schedule", (route) => false);
                  }
                : null,
          ),
        ],
      ),
      body: ScrollablePageBody(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Role",
                style: Theme.of(context).textTheme.labelLarge?.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onBackground)),
              ),
              const SizedBox(height: 5),
              ListTile(
                title: const Text("Analyst"),
                leading: Icon(
                  Icons.timeline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
                leading: Icon(
                  Icons.supervisor_account,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                trailing: Radio(
                    value: "8033_scouting_lead",
                    activeColor: Theme.of(context).colorScheme.primary,
                    groupValue: role,
                    onChanged: ((value) {
                      passwordProtected(
                          context, teamScoutingLeadCorrectPassword, () {
                        setState(() {
                          if (value == null) return;
                          role = value;
                        });
                      });
                    })),
              ),
              const SizedBox(height: 10),
              Text(
                "Analysts get access to data and picklists. Scouting Leads have additional tools for ensuring the accuracy of data and managing scouters.",
                style: Theme.of(context).textTheme.bodyMedium?.merge(
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _teamNumberController,
                decoration: InputDecoration(
                  label: const Text("Team"),
                  filled: true,
                  errorText:
                      int.tryParse(teamNumber) != null ? null : "Invalid",
                ),
                keyboardType: TextInputType.number,
                autocorrect: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  setState(() {
                    teamNumber = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              TournamentKeyPicker(
                onChanged: (value) {
                  setState(() {
                    tournament = value.key;
                    tournamentName = value.localized;
                  });
                },
                initialValue: Tournament(
                  widget.initialTournament,
                  widget.initialTournamentName,
                ),
                decoration: const InputDecoration(
                  labelText: "Tournament",
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _serverAuthorityController,
                decoration: InputDecoration(
                  label: const Text("Server Authority"),
                  filled: true,
                  errorText: validServerAuthority.hasMatch(serverAuthority)
                      ? null
                      : "Invalid",
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                onChanged: (value) {
                  setState(() {
                    serverAuthority = value;
                  });
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
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
                                  final prefs =
                                      await SharedPreferences.getInstance();

                                  await prefs.clear();
                                  await auth0.credentialsManager
                                      .clearCredentials();

                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                      "/loading", (route) => false);
                                },
                                style: ButtonStyle(
                                  elevation: MaterialStateProperty.all(0),
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith(
                                          (states) => Theme.of(context)
                                              .colorScheme
                                              .error),
                                  foregroundColor:
                                      MaterialStateProperty.resolveWith(
                                          (states) => Theme.of(context)
                                              .colorScheme
                                              .onError),
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
