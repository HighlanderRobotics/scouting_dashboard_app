import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<int>> getPickedTeams() async {
  final sharedPrefs = await SharedPreferences.getInstance();

  return (sharedPrefs.getStringList("picked_teams") ?? <String>[])
      .map((e) => int.parse(e))
      .toList();
}

Future<void> addPickedTeam(int team) async {
  final sharedPrefs = await SharedPreferences.getInstance();

  final pickedTeams = await getPickedTeams();

  if (pickedTeams.contains(team)) return; // Avoid duplicates

  await sharedPrefs.setStringList("picked_teams", [
    ...pickedTeams.map((e) => e.toString()),
    team.toString(),
  ]);
}

Future<void> removePickedTeam(int team) async {
  final sharedPrefs = await SharedPreferences.getInstance();

  List<int> pickedTeams = await getPickedTeams();

  pickedTeams.remove(team);

  await sharedPrefs.setStringList(
    "picked_teams",
    pickedTeams.map((e) => e.toString()).toList(),
  );
}

Future<void> removeAllPickedTeams() async {
  final sharedPrefs = await SharedPreferences.getInstance();

  await sharedPrefs.setStringList("picked_teams", []);
}

class MarkPickedTeamDialog extends StatefulWidget {
  const MarkPickedTeamDialog({super.key, this.onSubmit});

  final dynamic Function(int team)? onSubmit;

  @override
  State<MarkPickedTeamDialog> createState() => _MarkPickedTeamDialogState();
}

class _MarkPickedTeamDialogState extends State<MarkPickedTeamDialog> {
  String fieldValue = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Mark team as picked"),
      content: TextField(
        onChanged: (value) => setState(() {
          fieldValue = value;
        }),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          filled: true,
          label: Text("Team #"),
        ),
      ),
      actions: [
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: int.tryParse(fieldValue) == null
              ? null
              : () async {
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Adding..."),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  try {
                    await addPickedTeam(int.parse(fieldValue));

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Marked $fieldValue as picked"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Error: $error",
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } finally {
                    if (widget.onSubmit != null) {
                      widget.onSubmit!(int.parse(fieldValue));
                    }
                  }
                },
          child: const Text("Add"),
        )
      ],
    );
  }
}

class PickedTeamsPage extends StatefulWidget {
  const PickedTeamsPage({super.key});

  @override
  State<PickedTeamsPage> createState() => _PickedTeamsPageState();
}

class _PickedTeamsPageState extends State<PickedTeamsPage> {
  @override
  Widget build(BuildContext context) {
    dynamic Function()? onEdit;
    if (ModalRoute.of(context)!.settings.arguments != null) {
      onEdit = (ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>)['onEdit'];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Picked Teams"),
      ),
      body: FutureBuilder(
        future: getPickedTeams(),
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return ScrollablePageBody(children: [
              Text("Error: ${snapshot.error}"),
            ]);
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return Column(children: const [LinearProgressIndicator()]);
          }

          List<int> teams = snapshot.data!;

          return PageBody(
            padding: EdgeInsets.zero,
            child: ListView(
              children: teams
                  .map((team) => Dismissible(
                        key: Key(team.toString()),
                        direction: DismissDirection.endToStart,
                        onUpdate: (details) {
                          if ((details.reached && !details.previousReached) ||
                              (!details.reached && details.previousReached)) {
                            HapticFeedback.lightImpact();
                          }
                        },
                        background: Container(
                          color: Colors.red[900],
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const [
                                Icon(Icons.delete),
                                SizedBox(width: 30),
                              ],
                            ),
                          ),
                        ),
                        onDismissed: (direction) async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Removing..."),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          try {
                            await removePickedTeam(team);

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text("Removed $team from picked teams"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (error) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Error: $error",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            if (onEdit != null) onEdit();
                          }
                        },
                        child: ListTile(
                          title: Text(team.toString()),
                        ),
                      ))
                  .toList(),
            ),
          );
        }),
      ),
    );
  }
}
