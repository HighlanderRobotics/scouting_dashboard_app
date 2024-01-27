import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/picked_teams.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

class MutablePicklistPage extends StatefulWidget {
  const MutablePicklistPage({super.key});

  @override
  State<MutablePicklistPage> createState() => _MutablePicklistPageState();
}

class _MutablePicklistPageState extends State<MutablePicklistPage> {
  List<int>? pendingTeamList;
  List<int>? updatedTeamList;

  List<int> pickedTeamList = [];
  List<FlagConfiguration>? flagConfigurations;
  Map<int, Map<String, dynamic>> flagData = {};

  Future<void> refreshPickedTeams() async {
    final teams = await getPickedTeams();

    setState(() {
      pickedTeamList = teams;
    });
  }

  Future<void> refreshFlagConfigurations() async {
    final configs = await getPicklistFlags();

    setState(() {
      flagConfigurations = configs;
    });
  }

  @override
  void initState() {
    super.initState();

    refreshPickedTeams();
    refreshFlagConfigurations();
  }

  @override
  Widget build(BuildContext context) {
    final routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final picklist = routeArgs['picklist'] as MutablePicklist;
    final callback = routeArgs['callback'] as void Function();

    return Scaffold(
      appBar: AppBar(
        title: Text(picklist.name),
        bottom: pendingTeamList != null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(0),
                child: LinearProgressIndicator(),
              )
            : null,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => MarkPickedTeamDialog(
                  onSubmit: (team) {
                    refreshPickedTeams();
                  },
                ),
              );
            },
            icon: const Icon(Icons.format_strikethrough),
            tooltip: "Mark a team as picked",
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed("/picked_teams", arguments: <String, dynamic>{
                'onEdit': () {
                  refreshPickedTeams();
                }
              });
            },
            icon: const Icon(Icons.rule),
            tooltip: "View picked teams",
          ),
        ],
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: ReorderableListView(
          onReorder: (int oldIndex, int newIndex) async {
            List<int> newTeams =
                (updatedTeamList ?? picklist.teams).where((e) => true).toList();

            if (oldIndex < newIndex) {
              newIndex -= 1;
            }

            final int item = newTeams.removeAt(oldIndex);
            newTeams.insert(newIndex, item);

            setState(() {
              pendingTeamList = newTeams.where((e) => true).toList();
            });

            final newPicklist = MutablePicklist(
              name: picklist.name,
              uuid: picklist.uuid,
              teams: newTeams.where((e) => true).toList(),
            );

            try {
              await newPicklist.upload();
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    "Error moving team: ${error.toString()}",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
              );
              setState(() {
                pendingTeamList = null;
              });
              return;
            }

            setState(() {
              updatedTeamList = newTeams.where((e) => true).toList();
              pendingTeamList = null;
            });

            callback();
          },
          children: (pendingTeamList ?? updatedTeamList ?? picklist.teams)
              .map((team) => GestureDetector(
                    key: Key(team.toString()),
                    onLongPress: pendingTeamList == null ? null : () {},
                    child: ListTile(
                      textColor:
                          pickedTeamList.contains(team) ? Colors.red : null,
                      title: Text(team.toString()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_right,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ].withSpaceBetween(width: 16),
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/team_lookup',
                          arguments: {
                            'team': team,
                          },
                        );
                      },
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
