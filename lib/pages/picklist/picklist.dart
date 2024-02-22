import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/picklist_analysis.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/edit_picklist_flags.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:skeletons/skeletons.dart';

class MyPicklistPage extends StatefulWidget {
  const MyPicklistPage({super.key});

  @override
  State<MyPicklistPage> createState() => _MyPicklistPageState();
}

class _MyPicklistPageState extends State<MyPicklistPage> {
  final picklistVisualizationKey = GlobalKey<AnalysisVisualizationState>();

  @override
  Widget build(BuildContext context) {
    ConfiguredPicklist picklist = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['picklist'];

    Future<void> Function() onChanged = (ModalRoute.of(context)!
        .settings
        .arguments as Map<String, dynamic>)['onChanged'];

    return Scaffold(
      appBar: AppBar(
        title: Text(picklist.title),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Uploading..."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                await picklist.upload();

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Successfully uploaded picklist."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (error) {
                debugPrint((error as TypeError).stackTrace.toString());

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    "Error uploading picklist: $error",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ));
              }
            },
            icon: const Icon(Icons.upload),
            tooltip: "Share picklist with your team",
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed("/edit_picklist", arguments: {
                'picklist': picklist,
                'onChanged': () async {
                  await onChanged();

                  setState(() {});
                }
              });
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit picklist",
          )
        ],
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: PicklistVisuzlization(
          analysisFunction: MyPicklistAnalysis(picklist: picklist),
          key: picklistVisualizationKey,
        ),
      ),
    );
  }
}

class PicklistVisuzlization extends AnalysisVisualization {
  const PicklistVisuzlization({
    super.key,
    required PicklistAnalysis super.analysisFunction,
  });

  @override
  Widget loadingView() {
    return SkeletonListView(
      itemBuilder: (context, index) => SkeletonListTile(),
    );
  }

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    final result = snapshot.data['result'];
    final List<FlagConfiguration> flagConfigurations = snapshot.data['flags'];

    return ListView(
      children: (result as List<dynamic>)
          .map((teamData) => ListTile(
                title: Text(teamData['team'].toString()),
                contentPadding: const EdgeInsets.only(left: 16, right: 4),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlagRow(
                      flagConfigurations,
                      teamData['flags']
                          .asMap()
                          .map(
                            (k, value) => MapEntry(
                              value['type'],
                              value['result'],
                            ),
                          )
                          .cast<String, dynamic>(),
                      teamData['team'],
                      onEdit: () => super.loadData(),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed("/picklist_team_breakdown", arguments: {
                          'team': int.parse(teamData['team'].toString()),
                          'breakdown': teamData['breakdown'],
                          'unweighted': teamData['unweighted'],
                          'picklistTitle':
                              (analysisFunction as PicklistAnalysis)
                                  .picklistMeta
                                  .title,
                        });
                      },
                      icon: Icon(
                        Icons.balance,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      tooltip: "View ${teamData['team']}'s z-scores",
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed("/team_lookup", arguments: {
                          'team': int.parse(teamData['team'].toString()),
                        });
                      },
                      icon: Icon(
                        Icons.arrow_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      tooltip: "Open team lookup for ${teamData['team']}",
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class FlagRow extends StatelessWidget {
  const FlagRow(this.flagConfigurations, this.data, this.team,
      {this.onEdit, super.key});

  final List<FlagConfiguration> flagConfigurations;
  final Map<String, dynamic> data;
  final int team;
  final dynamic Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    int i = -1;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/edit_picklist_flags',
          arguments: EditPicklistFlagsArgs(
            initialFlags: flagConfigurations,
            initialFlagValues: data,
            team: team,
            onChange: (data) {
              if (onEdit != null) onEdit!();
            },
          ),
        );
      },
      child: Row(
        children: flagConfigurations.isEmpty
            ? [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  child: const Center(
                    child: Icon(Icons.add),
                  ),
                )
              ]
            : flagConfigurations
                .map((flag) {
                  i += 1;

                  return Hero(
                      tag: '$team-${flag.type.path}-$i',
                      child: flag.getWidget(context, data[flag.type.path]));
                })
                .toList()
                .withSpaceBetween(width: 10),
      ),
    );
  }
}

Widget tbaRankBadge(int team) {
  return SizedBox(
    height: 30,
    width: 30,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3F51B5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: FutureBuilder(
            future: getRank(team),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint(snapshot.error.toString());
                return const Icon(Icons.error);
              }

              if (snapshot.connectionState != ConnectionState.done) {
                return SkeletonAvatar(
                  style: SkeletonAvatarStyle(
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }

              return Text(
                snapshot.data == null ? "-" : snapshot.data.toString(),
              );
            }),
      ),
    ),
  );
}

Future<int?> getRank(int team) async {
  final sharedPrefs = await SharedPreferences.getInstance();

  final authority = (await getServerAuthority())!;
  final tournamentKey = sharedPrefs.getString("tournament");

  final response =
      await http.get(Uri.http(authority, '/API/manager/getRankOfTeam', {
    'teamKey': "frc$team",
    'tournamentKey': tournamentKey,
  }));

  if (response.statusCode != 200) {
    throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
  }

  return int.tryParse(response.body);
}
