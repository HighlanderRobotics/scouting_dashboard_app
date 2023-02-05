import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/picklist_analysis.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

class PicklistPage extends StatefulWidget {
  const PicklistPage({super.key});

  @override
  State<PicklistPage> createState() => _PicklistPageState();
}

class _PicklistPageState extends State<PicklistPage> {
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
      children: teams
          .map((teamNumber) => ListTile(
                title: Text(teamNumber),
                trailing: Icon(
                  Icons.arrow_right,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onTap: () {
                  Navigator.of(context).pushNamed("/team_lookup", arguments: {
                    'team': int.parse(teamNumber),
                  });
                },
              ))
          .toList(),
    );
  }
}
