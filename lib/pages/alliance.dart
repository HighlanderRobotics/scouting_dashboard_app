import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/alliance_analysis.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/models/reef_level.dart';
import 'package:scouting_dashboard_app/reusable/models/robot_roles.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';
import 'package:scouting_dashboard_app/reusable/value_tile.dart';

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
  const AllianceVizualization({
    super.key,
    required AllianceAnalysis super.analysisFunction,
  });

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
                    Tooltip(
                      message: teamData['role'] == null
                          ? "No data"
                          : RobotRole.values[teamData['role']].name,
                      child: Icon(teamData['role'] == null
                          ? Icons.question_mark
                          : RobotRole
                              .values[teamData['role'] as int].littleEmblem),
                    ),
                    const SizedBox(width: 3),
                    InkWell(
                      onTap: () => {
                        Navigator.of(context).pushNamed("/team_lookup",
                            arguments: <String, dynamic>{
                              'team': int.parse(teamData['team'].toString())
                            })
                      },
                      child: Text(
                        teamData['team'].toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Teleop points",
              style: Theme.of(context).textTheme.labelLarge!.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )),
            ),
            Text(
              analysisMap['totalPoints'] == null
                  ? '--'
                  : numberVizualizationBuilder(
                      analysisMap['totalPoints'] as num),
              style: Theme.of(context).textTheme.titleMedium!.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )),
            )
          ],
        ),
      ),
      const SizedBox(height: 10),
      reefStack(context, analysisMap),
      const SizedBox(height: 10),
      Row(
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: ValueTile(
              value: Text(numberVizualizationBuilder(analysisMap['processor'])),
              label: const Text('Processor'),
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: ValueTile(
              value: Text(numberVizualizationBuilder(analysisMap['net'])),
              label: const Text('Net'),
            ),
          ),
        ].withSpaceBetween(width: 10),
      ),
      const SizedBox(height: 10),
      AlllianceAutoPaths(data: analysisMap),
    ]);
  }
}

const autoPathColors = [
  Color(0xFF4255F9),
  Color(0xFF0D984D),
  Color(0xFFF95842),
];

class AlllianceAutoPaths extends StatefulWidget {
  const AlllianceAutoPaths({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  State<AlllianceAutoPaths> createState() => _AlllianceAutoPathsState();
}

class _AlllianceAutoPathsState extends State<AlllianceAutoPaths>
    with TickerProviderStateMixin {
  List<AutoPath?> selectedPaths = [
    null,
    null,
    null,
  ];

  late final AnimationController controller;
  late final AnimationController playPauseController;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: AnimatedBuilder(
          animation: controller,
          builder: (context, w) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 3),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: widget.data['teams']
                            .map((e) => Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                            "/auto_path_selector",
                                            arguments: <String, dynamic>{
                                              'team': e['team'].toString(),
                                              'autoPaths': (e['paths']
                                                      as List<dynamic>)
                                                  .map((path) =>
                                                      AutoPath.fromMap(path))
                                                  .toList(),
                                              'currentPath': selectedPaths[
                                                  widget.data['teams']
                                                      .indexOf(e)],
                                              'onSubmit': (AutoPath? newPath) {
                                                setState(() {
                                                  selectedPaths[widget
                                                      .data['teams']
                                                      .indexOf(e)] = newPath;
                                                });
                                              }
                                            });
                                      },
                                      child: Row(children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(10)),
                                              color: autoPathColors[widget
                                                  .data['teams']
                                                  .indexOf(e)],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          e['team'].toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .merge(
                                                TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                        ),
                                      ]),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      "Score",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .merge(TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                                    ),
                                    Text(
                                      selectedPaths[widget.data['teams']
                                                  .indexOf(e)] ==
                                              null
                                          ? "--"
                                          : numberVizualizationBuilder(
                                              selectedPaths[widget.data['teams']
                                                      .indexOf(e)]!
                                                  .scores
                                                  .cast<num>()
                                                  .average()),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .merge(
                                            TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                    ),
                                  ],
                                ))
                            .toList()
                            .cast<Widget>(),
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity:
                                selectedPaths.any((e) => e != null) ? 1 : 0.3,
                            child: AutoPathField(
                              paths: selectedPaths
                                  .where((e) => e != null)
                                  .map((path) => AutoPathWidget(
                                        animationProgress: controller.value == 0
                                            ? null
                                            : Duration(
                                                milliseconds:
                                                    (controller.value *
                                                            15 *
                                                            1000)
                                                        .round()),
                                        autoPath: path!,
                                        teamColor: autoPathColors[
                                            selectedPaths.indexOf(path)],
                                      ))
                                  .toList(),
                            ),
                          ),
                          if (!selectedPaths.any((e) => e != null))
                            Text(
                              "Tap a team to select a path",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                      AnimatedAutoPathControls(
                        controller: controller,
                        playPauseController: playPauseController,
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total auto score",
                          style: Theme.of(context).textTheme.labelLarge!.merge(
                              TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer)),
                        ),
                        Text(
                          selectedPaths.any((element) => element != null)
                              ? selectedPaths
                                  .where((path) => path != null)
                                  .map((path) => path!.scores
                                      .toList()
                                      .cast<num>()
                                      .average())
                                  .toList()
                                  .cast<num>()
                                  .sum()
                                  .toString()
                              : "--",
                          style: Theme.of(context).textTheme.bodyMedium!.merge(
                                TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            );
          }),
    );
  }
}

Container reefStack(
  BuildContext context,
  Map<String, dynamic> analysisMap, {
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  int index = 0;

  return Container(
    decoration: BoxDecoration(
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
    ),
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ([
        analysisMap['coralL1'],
        analysisMap['coralL2'],
        analysisMap['coralL3'],
        analysisMap['coralL4']
      ])
          .map((row) {
            index++;
            return Row(
              children: [
                Text(
                  ReefLevel.values[index].localizedDescripton,
                  style:
                      Theme.of(context).textTheme.labelLarge!.merge(TextStyle(
                            color: foregroundColor ??
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: (foregroundColor ??
                              Theme.of(context).colorScheme.onSurfaceVariant)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 55,
                      child: Text(
                        analysisMap['totalPoints'] == null
                            ? '--'
                            : numberVizualizationBuilder(row as num),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .merge(TextStyle(
                              color: foregroundColor ??
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            )),
                      ),
                    ),
                  ],
                ),
              ].withSpaceBetween(width: 7),
            );
          })
          .toList()
          .reversed
          .toList(),
    ),
  );
}
