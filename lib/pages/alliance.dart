import 'package:custom_qr_generator/custom_qr_generator.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/analysis_functions/alliance_analysis.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/auto_paths.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AlliancePage extends StatefulWidget {
  const AlliancePage({super.key});

  @override
  State<AlliancePage> createState() => _AlliancePageState();
}

class _AlliancePageState extends State<AlliancePage> {
  @override
  Widget build(BuildContext context) {
    List<int> teams = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['teams'];
    return Scaffold(
      appBar: AppBar(title: const Text("Alliance")),
      body: ScrollablePageBody(children: [
        AllianceVizualization(analysisFunction: AllianceAnalysis(teams: teams))
      ]),
    );
  }
}

class AllianceVizualization extends AnalysisVisualization {
  AllianceVizualization({required AllianceAnalysis super.analysisFunction});

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    Map<String, dynamic> analysisMap = snapshot.data;

    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: (analysisMap['teams'] as List<dynamic>)
            .map((teamData) => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(teamData['role'] == null
                        ? Icons.question_mark
                        : RobotRole
                            .values[teamData['role'] as int].littleEmblem),
                    const SizedBox(width: 3),
                    Text(
                      teamData['team'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ))
            .toList(),
      ),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total points",
              style: Theme.of(context).textTheme.labelLarge!.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )),
            ),
            Text(
              numberVizualizationBuilder(analysisMap['totalPoints'] as num),
              style: Theme.of(context).textTheme.titleLarge!.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )),
            )
          ],
        ),
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            AutoPaths(
                layers: ((analysisMap['teams']) as List<dynamic>)
                    .fold(<Map<String, dynamic>>[], (paths, teamData) {
                      paths
                          .addAll((teamData['paths'] as List<dynamic>).map((e) {
                        Map<String, dynamic> path = e;

                        return {
                          ...path,
                          'team': teamData['team'],
                          'highestFrequency':
                              (teamData['paths'] as List<dynamic>).fold(
                            0,
                            (previousValue, element) =>
                                element['frequency'] > previousValue
                                    ? element['frequency']
                                    : previousValue,
                          ),
                        };
                      }));

                      return paths;
                    })
                    .map(
                      (pathMap) => AutoPathLayer(
                          positions: ((pathMap['positions']) as List<dynamic>)
                              .map((e) => AutoPathPosition.values[e])
                              .toList(),
                          color: HSLColor.fromAHSL(
                            1,
                            int.parse(pathMap['team'] as String).toDouble() /
                                5 %
                                360,
                            pathMap['frequency'] / pathMap['highestFrequency'],
                            0.5,
                          ).toColor()),
                    )
                    .toList()),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: (analysisMap['teams'] as List<dynamic>)
                  .map((e) => e['team'] as String)
                  .toList()
                  .map((e) => Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    color: HSLColor.fromAHSL(
                                      1,
                                      int.parse(e).toDouble() / 5 % 360,
                                      1,
                                      0.5,
                                    ).toColor())),
                          ),
                          const SizedBox(width: 5),
                          Text(e),
                        ],
                      ))
                  .toList(),
            )
          ],
        ),
      ),
    ]);
  }
}
