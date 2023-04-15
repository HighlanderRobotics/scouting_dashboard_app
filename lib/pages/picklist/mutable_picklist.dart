import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

class MutablePicklistPage extends StatefulWidget {
  const MutablePicklistPage({super.key});

  @override
  State<MutablePicklistPage> createState() => _MutablePicklistPageState();
}

class _MutablePicklistPageState extends State<MutablePicklistPage> {
  List<int>? pendingTeamList;
  List<int>? updatedTeamList;

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
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
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
                      title: Text(team.toString()),
                      leading: tbaRankBadge(team),
                      trailing: Icon(
                        Icons.arrow_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
