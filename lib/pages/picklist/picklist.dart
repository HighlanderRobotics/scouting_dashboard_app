import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/picklist_analysis.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

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
