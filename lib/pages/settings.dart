import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String? initialRole;
  String? initialTournament;
  String? initialServerAuthority;

  Future<void> setInitialValues() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      initialRole = prefs.getString("role");
      initialTournament = prefs.getString("tournament");
      initialServerAuthority = prefs.getString("serverAuthority");
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
        initialServerAuthority == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return LoadedSettings(
          initialRole: initialRole!,
          initialTournament: initialTournament!,
          initialServerAuthority: initialServerAuthority!);
    }
  }
}

class LoadedSettings extends StatefulWidget {
  const LoadedSettings({
    Key? key,
    required this.initialRole,
    required this.initialTournament,
    required this.initialServerAuthority,
  }) : super(key: key);

  final String initialRole;
  final String initialTournament;
  final String initialServerAuthority;

  @override
  State<LoadedSettings> createState() => _LoadedSettingsState();
}

class _LoadedSettingsState extends State<LoadedSettings> {
  late String role = widget.initialRole;
  late String tournament = widget.initialTournament;
  late String serverAuthority = widget.initialServerAuthority;
  late final TextEditingController _serverAuthorityController =
      TextEditingController(text: serverAuthority);

  bool getAllowSave() {
    // Check for changes
    if (role == widget.initialRole &&
        tournament == widget.initialTournament &&
        serverAuthority == widget.initialServerAuthority) return false;

    // Validate new values
    if (!validServerAuthority.hasMatch(serverAuthority)) return false;

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
            color: Colors.green,
            onPressed: getAllowSave()
                ? () async {
                    final prefs = await SharedPreferences.getInstance();

                    await prefs.setString("role", role);
                    await prefs.setString("tournament", tournament);
                    await prefs.setString("serverAuthority", serverAuthority);

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
              Text(
                "Both get access to processed scouting data. Scouting leads get additional tools for modifying the scout schedule and scanning QR codes.",
                style: Theme.of(context).textTheme.bodyMedium?.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onBackground)),
              ),
              const SizedBox(height: 40),
              DropdownSearch(
                popupProps: const PopupProps.menu(
                  // showSelectedItems: true,
                  fit: FlexFit.loose,
                ),
                selectedItem: getTournamentByKey(tournament),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration:
                      InputDecoration(labelText: "Tournament", filled: true),
                ),
                items: tournamentList,
                onChanged: (value) {
                  setState(() {
                    tournament = value.key;
                  });
                },
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

                                  await prefs.remove("role");
                                  await prefs.remove("tournament");
                                  await prefs.remove("serverAuthority");
                                  await prefs.remove("onboardingCompleted");
                                  await prefs.remove("picklists");

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
