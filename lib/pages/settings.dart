import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/onboarding/onboarding_page.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/inset_picker.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/delete_account.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_tournaments.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_user_profile.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/source_data/source_teams.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/source_data/source_tournaments.dart';
import 'package:scouting_dashboard_app/reusable/models/user_profile.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/tournament_key_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletons/skeletons.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Tournament? selectedTournament;

  Future<void> load() async {
    final tournament = await Tournament.getCurrent();

    setState(() {
      selectedTournament = tournament;
    });
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: const [CodeViewerButton()],
      ),
      drawer: const GlobalNavigationDrawer(),
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
              const SizedBox(height: 28),
              Text(
                "Use data from tournaments",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 7),
              const TournamentSourceSelector(),
              const SizedBox(height: 28),
              TournamentKeyPicker(
                decoration: const InputDecoration(
                  filled: true,
                  labelText: "At tournament",
                ),
                onChanged: (tournament) {
                  setState(() {
                    selectedTournament = tournament;
                  });
                },
              ),
              if (cachedUserProfile?.role == UserRole.scoutingLead &&
                  selectedTournament != null) ...[
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pushWidget(const DataExportPage());
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: const Text("Export CSV"),
                ),
              ],
              const AnalystsBox(),
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

// Instead of a button group, it has a container that displays the current value ("2023 Chezy Champs" or "18 tournaments") with a button to change it (new page)
class TournamentSourceSelector extends StatefulWidget {
  const TournamentSourceSelector({super.key});

  @override
  State<TournamentSourceSelector> createState() =>
      _TournamentSourceSelectorState();
}

class _TournamentSourceSelectorState extends State<TournamentSourceSelector> {
  List<Tournament>? tournaments;
  List<String>? selectedTournamentKeys;
  List<Tournament>? get selectedTournaments => tournaments
      ?.where(
        (element) => selectedTournamentKeys!.contains(element.key),
      )
      .toList();

  String? errorMessage;

  String? get currentTournamentText {
    if (selectedTournaments == null) return null;

    if (selectedTournaments!.isEmpty) return "None";

    if (selectedTournaments!.length == 1) {
      return selectedTournaments!.first.localized;
    }

    return "${selectedTournaments!.length} tournaments";
  }

  bool get isLoading => tournaments == null || selectedTournamentKeys == null;

  Future<void> load() async {
    try {
      final partialTournaments = await lovatAPI.getTournaments();

      setState(() {
        tournaments = partialTournaments.tournaments;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load tournaments";
      });
    }

    try {
      final selectedTournamentKeys = await lovatAPI.getSourceTournamentKeys();

      setState(() {
        this.selectedTournamentKeys = selectedTournamentKeys;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load selected tournaments";
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
    if (isLoading && errorMessage == null) {
      return const SkeletonAvatar(
        style: SkeletonAvatarStyle(
          height: 60,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      );
    }

    if (isLoading && errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        height: 60,
        child: Center(
          child: MediumErrorMessage(message: errorMessage),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      height: 60,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                currentTournamentText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushWidget(
                  TournamentSourceSelectorSettingsPage(
                    onSubmit: () async {
                      await load();
                    },
                  ),
                );
              },
              child: const Text("Change"),
            ),
          ],
        ),
      ),
    );
  }
}

// List of tournaments, select multiple, search, select all/deselect all, submit
class TournamentSourceSelectorSettingsPage extends StatefulWidget {
  const TournamentSourceSelectorSettingsPage({
    super.key,
    this.onSubmit,
  });

  final dynamic Function()? onSubmit;

  @override
  State<TournamentSourceSelectorSettingsPage> createState() =>
      _TournamentSourceSelectorSettingsPageState();
}

class _TournamentSourceSelectorSettingsPageState
    extends State<TournamentSourceSelectorSettingsPage> {
  List<Tournament>? tournaments;
  List<String>? selectedTournamentKeys;

  String? errorMessage;

  bool get isLoading => tournaments == null || selectedTournamentKeys == null;

  bool isSubmitLoading = false;

  String filterText = "";
  List<Tournament>? get filteredTournaments => tournaments
      ?.where((element) =>
          element.localized.toLowerCase().contains(filterText.toLowerCase()))
      .toList();

  Future<void> load() async {
    try {
      final partialTournaments = await lovatAPI.getTournaments();

      setState(() {
        tournaments = partialTournaments.tournaments;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load tournaments";
      });
    }

    try {
      final selectedTournamentKeys = await lovatAPI.getSourceTournamentKeys();

      setState(() {
        this.selectedTournamentKeys = selectedTournamentKeys;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load selected tournaments";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  void onSelectionChanged(List<String> newSelectedTournamentKeys) {
    setState(() {
      selectedTournamentKeys = newSelectedTournamentKeys;
    });
  }

  void selectAll() {
    setState(() {
      selectedTournamentKeys = tournaments!.map((e) => e.key).toList();
    });
  }

  bool get isAllSelected =>
      selectedTournamentKeys?.length == tournaments?.length;

  void deselectAll() {
    setState(() {
      selectedTournamentKeys = [];
    });
  }

  Future<void> onSubmit() async {
    setState(() {
      isSubmitLoading = true;
    });

    try {
      await lovatAPI.setSourceTournamentKeys(selectedTournamentKeys!);
      widget.onSubmit?.call();
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        errorMessage = "Failed to save source tournament settings";
      });
    } finally {
      setState(() {
        isSubmitLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (isLoading && errorMessage == null) {
      body = SkeletonListView(
        itemBuilder: (context, index) => SkeletonListTile(),
      );
    } else if (isLoading && errorMessage != null) {
      body = FriendlyErrorView(errorMessage: errorMessage, onRetry: load);
    } else {
      body = ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (filteredTournaments!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("No tournaments"),
            )
          else
            for (final tournament in filteredTournaments!)
              CheckboxListTile(
                value: selectedTournamentKeys!.contains(tournament.key),
                onChanged: (value) {
                  if (value!) {
                    setState(() {
                      selectedTournamentKeys!.add(tournament.key);
                    });
                  } else {
                    setState(() {
                      selectedTournamentKeys!.remove(tournament.key);
                    });
                  }
                },
                title: Text(tournament.localized),
              ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text("Select tournaments"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        filterText = value;
                      });
                    },
                    decoration: const InputDecoration(
                      filled: true,
                      labelText: "Search",
                    ),
                  ),
                ),
                if (isSubmitLoading) const LinearProgressIndicator(),
              ],
            ),
          )),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          body,
          Padding(
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonal(
                    onPressed: isSubmitLoading || isLoading
                        ? null
                        : isAllSelected
                            ? deselectAll
                            : selectAll,
                    child: Text(isAllSelected ? "Deselect all" : "Select all"),
                  ),
                  FilledButton(
                    onPressed: isSubmitLoading || isLoading ? null : onSubmit,
                    child: const Text("Save"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataExportDrawer extends StatefulWidget {
  const DataExportDrawer(this.exportMode, {super.key});

  final CSVExportMode exportMode;

  @override
  State<DataExportDrawer> createState() => _DataExportDrawerState();
}

class _DataExportDrawerState extends State<DataExportDrawer> {
  String? errorMessage;

  Future<void> export() async {
    try {
      final tournament = await Tournament.getCurrent();
      if (tournament == null) {
        setState(() {
          errorMessage = "No tournament selected";
        });
        return;
      }
      final csv = await lovatAPI.getCSVExport(tournament, widget.exportMode);

      debugPrint(csv);

      final csvFile = XFile.fromData(
        utf8.encode(csv),
        mimeType: "text/csv",
      );

      if (mounted) {
        Share.shareXFiles([csvFile], subject: "${tournament.localized} data");
        Navigator.of(context).pop();
      }
    } on LovatAPIException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        errorMessage = "Failed to export data";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    export();
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return FriendlyErrorView(errorMessage: errorMessage, onRetry: export);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Exporting data...",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class AnalystsBox extends StatefulWidget {
  const AnalystsBox({super.key});

  @override
  State<AnalystsBox> createState() => _AnalystsBoxState();
}

class _AnalystsBoxState extends State<AnalystsBox> {
  List<Analyst>? analysts;
  bool loaded = false;
  String? errorMessage;

  Future<void> load() async {
    try {
      final analysts = await lovatAPI.getAnalysts();

      setState(() {
        this.analysts = analysts;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load analysts";
      });
    } finally {
      setState(() {
        loaded = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  String? get currentAnalystsText {
    if (analysts == null) return null;

    if (analysts!.isEmpty) return "Nobody to promote";

    if (analysts!.length == 1) {
      return analysts!.first.name;
    }

    return "${analysts!.length} analysts";
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded && errorMessage == null) {
      return const SkeletonAvatar(
        style: SkeletonAvatarStyle(
          width: 200,
          height: 60,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      );
    }

    if (!loaded && errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        height: 60,
        child: Center(
          child: MediumErrorMessage(message: errorMessage),
        ),
      );
    }

    if (loaded && analysts == null) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Text(
          "Promote analysts",
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 7),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    currentAnalystsText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushWidget(AnalystPromotionPage(
                      onSubmit: () {
                        load();
                      },
                    ));
                  },
                  child: const Text("Manage"),
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: MediumErrorMessage(message: errorMessage),
          ),
      ],
    );
  }
}

class AnalystPromotionPage extends StatefulWidget {
  const AnalystPromotionPage({super.key, this.onSubmit});

  final dynamic Function()? onSubmit;

  @override
  State<AnalystPromotionPage> createState() => _AnalystPromotionPageState();
}

class _AnalystPromotionPageState extends State<AnalystPromotionPage> {
  List<Analyst>? analysts;
  String? errorMessage;
  bool submitting = false;

  Future<void> load() async {
    try {
      final analysts = await lovatAPI.getAnalysts();

      setState(() {
        this.analysts = analysts;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load analysts";
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
    Widget body;

    if (analysts == null && errorMessage == null) {
      body = SkeletonListView(
        itemBuilder: (context, index) => SkeletonListTile(),
      );
    } else if (analysts == null && errorMessage != null) {
      body = FriendlyErrorView(errorMessage: errorMessage, onRetry: load);
    } else if (analysts!.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: Text("No analysts to promote"),
        ),
      );
    } else {
      body = ListView(
        children: [
          for (final analyst in analysts!)
            ListTile(
              title: Text(analyst.name),
              subtitle: Text(analyst.email),
              trailing: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    submitting = true;
                    errorMessage = null;
                  });

                  try {
                    await analyst.promote();
                    await load();
                    widget.onSubmit?.call();
                  } catch (e) {
                    setState(() {
                      errorMessage = "Failed to promote analyst";
                    });
                  } finally {
                    setState(() {
                      submitting = false;
                    });
                  }
                },
                child: const Text("Promote"),
              ),
            )
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Promote analysts"),
        bottom: submitting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(5),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: body,
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

class CodeViewerButton extends StatefulWidget {
  const CodeViewerButton({super.key});

  @override
  State<CodeViewerButton> createState() => _CodeViewerButtonState();
}

class _CodeViewerButtonState extends State<CodeViewerButton> {
  String? code;

  Future<void> load() async {
    try {
      final code = await lovatAPI.getTeamCode();

      setState(() {
        this.code = code;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Error getting team code: $e",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    if (code == null) {
      return const SizedBox();
    }

    return IconButton(
      onPressed: () {
        Navigator.of(context).pushWidget(
          CodeViewerPage(
            code: code!,
          ),
        );
      },
      icon: const Icon(Icons.pin),
      tooltip: "View team code",
    );
  }
}

class CodeViewerPage extends StatelessWidget {
  const CodeViewerPage({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Team code"),
      ),
      body: ScrollablePageBody(children: [
        Column(children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 7),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Copied to clipboard"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: "Copy to clipboard",
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "Share this code with your team members to allow them to join.",
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ]),
      ]),
    );
  }
}

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  Tournament? tournament;
  String? errorText;

  CSVExportMode? exportMode;

  void loadData() async {
    Tournament? tournament = await Tournament.getCurrent();

    if (tournament == null) {
      setState(() {
        errorText = 'No tournament selected';
      });
    } else {
      setState(() {
        this.tournament = tournament;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Widget body(BuildContext context) {
    if (errorText != null) {
      return FriendlyErrorView(errorMessage: errorText, onRetry: loadData);
    }

    return PageBody(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Download a file containing data collected at ${tournament?.localized ?? 'your tournament'}, by all teams in your data set.",
        ),
        InsetPicker(
          CSVExportMode.values,
          titleBuilder: (mode) => mode.localizedDescription,
          descriptionBuilder: (mode) => mode.longLocalizedDescription,
          selectedItem: exportMode,
          onChanged: (value) => setState(() => exportMode = value),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: exportMode == null
              ? null
              : () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => DataExportDrawer(exportMode!),
                  );
                },
          icon: const Icon(Icons.download),
          label: const Text("Export"),
        ),
      ].withSpaceBetween(height: 10),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CSV Export")),
      body: body(context),
    );
  }
}
