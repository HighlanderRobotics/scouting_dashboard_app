import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/onboarding/onboarding_page.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletons/skeletons.dart';

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
      body: ScrollablePageBody(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Use data from teams",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 7),
              const TeamSourceSelector(),
              const SizedBox(height: 40),
              const ResetAppButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class TeamSourceSelector extends StatefulWidget {
  const TeamSourceSelector({super.key});

  @override
  State<TeamSourceSelector> createState() => _TeamSourceSelectorState();
}

class _TeamSourceSelectorState extends State<TeamSourceSelector> {
  SourceTeamSettingsMode? mode;
  List<int>? teams;
  int? thisTeamNumber;
  bool thisTeamLoaded = false;

  bool get isLoading => mode == null || !thisTeamLoaded;
  String? errorMesssage;

  Future<void> load() async {
    try {
      final sourceTeamSettings = await lovatAPI.getSourceTeamSettings();

      debugPrint("${sourceTeamSettings.mode} ${sourceTeamSettings.teams}");

      setState(() {
        mode = sourceTeamSettings.mode;
        teams = sourceTeamSettings.teams;
      });
    } catch (e) {
      setState(() {
        errorMesssage = "Failed to load source teams";
      });
    }

    try {
      final profile = await lovatAPI.getUserProfile();
      final thisTeamNumber = profile.team?.number;

      setState(() {
        this.thisTeamNumber = thisTeamNumber;
        thisTeamLoaded = true;
      });
    } catch (e) {
      setState(() {
        errorMesssage = "Failed to load profile";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("thisTeam: $thisTeamNumber");
    if (isLoading && errorMesssage == null) {
      return const SkeletonAvatar(
        style: SkeletonAvatarStyle(
          width: 200,
          height: 48,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
      );
    }

    if (isLoading && errorMesssage != null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(50),
        ),
        height: 48,
        child: Center(
          child: MediumErrorMessage(message: errorMesssage),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<SourceTeamSettingsMode>(
          segments: [
            if (thisTeamNumber != null)
              ButtonSegment(
                value: SourceTeamSettingsMode.thisTeam,
                label: Text(thisTeamNumber.toString()),
              ),
            const ButtonSegment(
              value: SourceTeamSettingsMode.allTeams,
              label: Text("All"),
            ),
            ButtonSegment(
              value: SourceTeamSettingsMode.specificTeams,
              label: Text(
                teams == null
                    ? "Choose..."
                    : "${teams!.length} team${teams!.length == 1 ? "" : "s"}",
              ),
            ),
          ],
          multiSelectionEnabled: false,
          emptySelectionAllowed: true,
          selected: {mode!},
          onSelectionChanged: (newMode) {
            final tappedMode = newMode.firstOrNull ?? mode;

            if (tappedMode != SourceTeamSettingsMode.specificTeams) {
              setState(() {
                mode = null;
                teams = null;
              });

              (() async {
                try {
                  await lovatAPI.setSourceTeams(tappedMode!);
                  await load();
                } catch (e) {
                  setState(() {
                    errorMesssage = "Failed to save source team settings";
                  });
                }
              })();
            } else {
              Navigator.of(context).pushNamed(
                "/specific_source_teams",
                arguments: SpecificSourceTeamsArguments(
                  initialTeams: teams,
                  submitText: "Save",
                  onSubmit: (teams) async {
                    final teamNumbers = teams.map((e) => e.number).toList();
                    final navigator = Navigator.of(context);

                    setState(() {
                      mode = SourceTeamSettingsMode.specificTeams;
                      this.teams = teamNumbers;
                    });

                    try {
                      await lovatAPI.setSourceTeams(
                        SourceTeamSettingsMode.specificTeams,
                        teams: teamNumbers,
                      );
                      await load();
                      navigator.popUntil(
                        (route) => route.settings.name == "/settings",
                      );
                    } catch (e) {
                      setState(() {
                        errorMesssage = "Failed to save source team settings";
                      });
                    }
                  },
                ),
              );
            }
          },
        ),
        if (errorMesssage != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: MediumErrorMessage(message: errorMesssage),
          ),
      ],
    );
  }
}

class MediumErrorMessage extends StatelessWidget {
  const MediumErrorMessage({
    super.key,
    required this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error,
          color: Theme.of(context).colorScheme.error,
        ),
        Text(
          message!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ].withSpaceBetween(width: 5),
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
          builder: (context) => const DeleteConfigurationDialog(),
          barrierDismissible: false,
        );
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

class DeleteConfigurationDialog extends StatefulWidget {
  const DeleteConfigurationDialog({
    super.key,
  });

  @override
  State<DeleteConfigurationDialog> createState() =>
      _DeleteConfigurationDialogState();
}

class _DeleteConfigurationDialogState extends State<DeleteConfigurationDialog> {
  bool willDeleteAccount = false;
  bool loading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete configuration?"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              "If you continue, you will erase all the data this app has saved and reset it to how it came when you first installed it. If you so choose, you can also delete your account."),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: willDeleteAccount,
                onChanged: (value) {
                  setState(() {
                    willDeleteAccount = value!;
                  });
                },
              ),
              const Text("Delete my account"),
            ],
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: MediumErrorMessage(message: errorMessage),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: loading
              ? null
              : () async {
                  setState(() {
                    loading = true;
                    errorMessage = null;
                  });

                  try {
                    if (willDeleteAccount) {
                      await lovatAPI.deleteAccount();
                    }

                    final prefs = await SharedPreferences.getInstance();

                    await prefs.clear();
                    await auth0.credentialsManager.clearCredentials();

                    Navigator.of(context)
                        .pushNamedAndRemoveUntil("/loading", (route) => false);
                  } catch (e) {
                    setState(() {
                      errorMessage = "Failed to delete configuration";
                    });
                    return;
                  } finally {
                    setState(() {
                      loading = false;
                    });
                  }
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
    );
  }
}
