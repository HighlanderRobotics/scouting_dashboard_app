import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/picklist_analysis.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/role_exclusive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:skeletons/skeletons.dart';

class MyPicklistPage extends StatefulWidget {
  const MyPicklistPage({super.key});

  @override
  State<MyPicklistPage> createState() => _MyPicklistPageState();
}

class _MyPicklistPageState extends State<MyPicklistPage> {
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
          RoleExclusive(
            roles: const ["8033_analyst", "8033_scouting_lead"],
            child: IconButton(
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
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                  ));
                }
              },
              icon: const Icon(Icons.upload),
            ),
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
          )
        ],
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: PicklistVisuzlization(
          analysisFunction: PicklistAnalysis(picklist: picklist),
        ),
      ),
    );
  }
}

class PicklistVisuzlization extends AnalysisVisualization {
  PicklistVisuzlization({required super.analysisFunction});

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    List<String> teams =
        snapshot.data.map((e) => e['team'].toString()).toList().cast<String>();

    return ListView(
      children: (snapshot.data as List<dynamic>)
          .map((teamData) => ListTile(
                leading: tbaRankBadge(teamData['team']),
                title: Text(teamData['team'].toString()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed("/picklist_team_breakdown", arguments: {
                          'team': int.parse(teamData['team'].toString()),
                          'breakdown': teamData['breakdown'],
                          'unweighted': teamData['unweighted'],
                          'picklistTitle':
                              (analysisFunction as PicklistAnalysis)
                                  .picklist
                                  .title,
                        });
                      },
                      icon: Icon(
                        Icons.balance,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed("/team_lookup", arguments: {
                          'team': int.parse(teamData['team'].toString()),
                        });
                      },
                      icon: Icon(
                        Icons.dashboard_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
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
