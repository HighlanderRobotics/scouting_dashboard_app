import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_alliance_analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/robot_roles.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';
import 'package:scouting_dashboard_app/reusable/value_tile.dart';

class AlliancePage extends StatefulWidget {
  const AlliancePage({super.key});

  @override
  State<AlliancePage> createState() => _AlliancePageState();
}

class _AlliancePageState extends State<AlliancePage> {
  late List<int> teams;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    teams = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['teams'];
  }

  @override
  Widget build(BuildContext context) {
    return StaleRefreshBuilder(
      query: lovatAPI.allianceAnalysisQuery(teams),
      builder: (context, result) {
        final data = result.data;
        Widget body;
        if (result.hasError && data == null) {
          body = FriendlyErrorView.result(result);
        } else if (data == null) {
          body = const Center(child: CircularProgressIndicator());
        } else {
          body = ScrollablePageBody(children: [_AllianceContent(data: data)]);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Alliance"),
            bottom: StaleRefreshIndicator.result(result),
          ),
          body: body,
        );
      },
    );
  }
}

class _AllianceContent extends StatefulWidget {
  const _AllianceContent({required this.data});

  final AllianceAnalysis data;

  @override
  State<_AllianceContent> createState() => _AllianceContentState();
}

class _AllianceContentState extends State<_AllianceContent> {
  @override
  Widget build(BuildContext context) {
    final analysis = widget.data;

    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: analysis.teams
            .map((teamData) => Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: teamData.role == null
                          ? "No data"
                          : teamData.robotRole!.name,
                      child: Icon(teamData.role == null
                          ? Icons.question_mark
                          : teamData.robotRole!.littleEmblem),
                    ),
                    const SizedBox(width: 3),
                    InkWell(
                      onTap: () => {
                        Navigator.of(context).pushNamed("/team_lookup",
                            arguments: <String, dynamic>{'team': teamData.team})
                      },
                      child: Text(
                        teamData.team.toString(),
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
              analysis.totalPoints == null
                  ? '--'
                  : numToStringRounded(analysis.totalPoints),
              style: Theme.of(context).textTheme.titleMedium!.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )),
            )
          ],
        ),
      ),
      const SizedBox(height: 10),
      reefStack(context, analysis),
      const SizedBox(height: 10),
      Row(
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: ValueTile(
              value: Text(numToStringRounded(analysis.totalBallThroughput)),
              label: const Text('Total output'),
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: ValueTile(
              value: Text(numToStringRounded(analysis.totalFuelOutputted)),
              label: const Text('Hub shots'),
            ),
          ),
        ].withSpaceBetween(width: 10),
      ),
      const SizedBox(height: 10),
      AlllianceAutoPaths(data: analysis),
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

  final AllianceAnalysis data;

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
      duration: const Duration(seconds: 20),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        children: widget.data.teams
                            .map((e) => Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                            "/auto_path_selector",
                                            arguments: <String, dynamic>{
                                              'team': e.team.toString(),
                                              'autoPaths': e.paths,
                                              'currentPath': selectedPaths[
                                                  widget.data.teams.indexOf(e)],
                                              'onSubmit': (AutoPath? newPath) {
                                                setState(() {
                                                  selectedPaths[widget
                                                      .data.teams
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
                                              color: autoPathColors[
                                                  widget.data.teams.indexOf(e)],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          e.team.toString(),
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
                                      selectedPaths[widget.data.teams
                                                  .indexOf(e)] ==
                                              null
                                          ? "--"
                                          : numToStringRounded(selectedPaths[
                                                  widget.data.teams.indexOf(e)]!
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
                                                            20 *
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
  AllianceAnalysis analysis, {
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  final startTimeLists = [
    analysis.l1StartTime,
    analysis.l2StartTime,
    analysis.l3StartTime
  ];

  return Container(
    decoration: BoxDecoration(
      color: backgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          border: TableBorder(
            horizontalInside: BorderSide(
              color: foregroundColor?.withValues(alpha: 0.5) ??
                  Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                const SizedBox(),
                for (int col = 0; col < 3; col++)
                  SizedBox(
                    height: 38,
                    child: Center(
                      child: Text(
                        analysis.teams.length > col
                            ? analysis.teams[col].team.toString()
                            : '--',
                        style: Theme.of(context).textTheme.labelLarge!.merge(
                              TextStyle(
                                color: foregroundColor ??
                                    Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                      ),
                    ),
                  ),
              ],
            ),
            for (var row = 0; row < 3; row++)
              TableRow(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 38,
                    child: Text(
                      'L${row + 1} Start',
                      style: Theme.of(context).textTheme.labelLarge!.merge(
                            TextStyle(
                              color: foregroundColor ??
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                    ),
                  ),
                  for (int col = 0; col < 3; col++)
                    Center(
                      child: Text(
                        (() {
                          final list = startTimeLists[row];
                          if (list.length <= col || list[col] == null) {
                            return '--';
                          }
                          return '${numToStringRounded(list[col])}s';
                        })(),
                        style: Theme.of(context).textTheme.labelLarge!.merge(
                              TextStyle(
                                color: foregroundColor ??
                                    Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    ),
  );
}
