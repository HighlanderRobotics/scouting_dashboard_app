import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/picked_teams.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
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
              await newPicklist.update();
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
                          if (flagConfigurations != null)
                            MutablePicklistFlagRow(
                              onLoad: (data) {
                                setState(() {
                                  flagData[team] = data;
                                });
                              },
                              flagConfigurations: flagConfigurations!,
                              flagData: flagData,
                              team: team,
                              onEdit: () {
                                refreshFlagConfigurations();
                                setState(() {
                                  flagData = {};
                                });
                              },
                            ),
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

class MutablePicklistFlagRow extends StatefulWidget {
  const MutablePicklistFlagRow({
    super.key,
    required this.flagData,
    required this.team,
    required this.flagConfigurations,
    required this.onLoad,
    required this.onEdit,
  });

  final Map<int, Map<String, dynamic>> flagData;
  final int team;
  final List<FlagConfiguration> flagConfigurations;
  final dynamic Function(Map<String, dynamic> data) onLoad;
  final dynamic Function() onEdit;

  @override
  State<MutablePicklistFlagRow> createState() => _MutablePicklistFlagRowState();
}

class _MutablePicklistFlagRowState extends State<MutablePicklistFlagRow> {
  Future<void> loadData() async {
    final flags = await lovatAPI.getFlags(
      widget.flagConfigurations.map((e) => e.type.path).toList(),
      widget.team,
    );

    widget.onLoad(flags.asMap().map(
          (key, value) => MapEntry(
            widget.flagConfigurations[key].type.path,
            value,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.flagData.containsKey(widget.team)) {
      loadData();

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.flagConfigurations
            .map((e) => const SkeletonFlag())
            .toList()
            .withSpaceBetween(width: 10),
      );
    }

    return FlagRow(
      widget.flagConfigurations,
      widget.flagData[widget.team]!,
      widget.team,
      onEdit: widget.onEdit,
    );
  }
}
