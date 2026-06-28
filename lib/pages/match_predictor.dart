import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/pages/alliance.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_alliance_analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_match_prediction.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/robot_roles.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';
import 'package:scouting_dashboard_app/reusable/value_tile.dart';

class MatchPredictorPage extends StatefulWidget {
  const MatchPredictorPage({super.key});

  @override
  State<MatchPredictorPage> createState() => _MatchPredictorPageState();
}

class _MatchPredictorPageState extends State<MatchPredictorPage> {
  late List<int> _teams;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments! as Map<String, dynamic>;
    _teams = [
      int.parse(args['red1']),
      int.parse(args['red2']),
      int.parse(args['red3']),
      int.parse(args['blue1']),
      int.parse(args['blue2']),
      int.parse(args['blue3']),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasDrawer = ModalRoute.of(context)!.settings.arguments == null
        ? const GlobalNavigationDrawer()
        : null;

    return StaleRefreshBuilder(
      query: lovatAPI.matchPrediction(
          _teams[0], _teams[1], _teams[2], _teams[3], _teams[4], _teams[5]),
      builder: (context, result) {
        final prediction = result.data;
        final notEnoughData =
            result.error?.contains("Not enough data") == true &&
                prediction == null;

        if (notEnoughData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Match Predictor"),
              bottom: StaleRefreshIndicator.result(result),
            ),
            body: notEnoughDataMessage(),
            drawer: hasDrawer,
          );
        }

        if (prediction == null) {
          if (result.error != null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Match Predictor"),
                bottom: StaleRefreshIndicator.result(result),
              ),
              body: PageBody(child: Text("Error: ${result.error}")),
              drawer: hasDrawer,
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text("Match Predictor"),
            ),
            body: const PageBody(child: LinearProgressIndicator()),
            drawer: hasDrawer,
          );
        }

        return DefaultTabController(
          length: 2,
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxHeight > constraints.maxWidth) {
              // Portrait
              return Scaffold(
                appBar: AppBar(
                  title: const Text("Match Predictor"),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(89),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: WinningPrediction(
                            redWinning: prediction.redWinning,
                            blueWinning: prediction.blueWinning,
                          ),
                        ),
                        const TabBar(tabs: [
                          Column(
                            children: [
                              Text("Red"),
                              SizedBox(height: 7),
                            ],
                          ),
                          Column(
                            children: [
                              Text("Blue"),
                              SizedBox(height: 7),
                            ],
                          ),
                        ]),
                        StaleRefreshIndicator.result(result),
                      ],
                    ),
                  ),
                ),
                body: TabBarView(children: [
                  ScrollablePageBody(children: [
                    allianceTab(0, prediction.redAlliance),
                  ]),
                  ScrollablePageBody(children: [
                    allianceTab(1, prediction.blueAlliance),
                  ]),
                ]),
                drawer: hasDrawer,
              );
            } else {
              // Landscape
              return Scaffold(
                appBar: AppBar(
                  title: const Text("Match Predictor"),
                  bottom: StaleRefreshIndicator.result(result),
                ),
                body: SafeArea(
                  bottom: false,
                  child: ListView(children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: WinningPrediction(
                        redWinning: prediction.redWinning,
                        blueWinning: prediction.blueWinning,
                      ),
                    ),
                    Row(children: [
                      Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: allianceTab(0, prediction.redAlliance),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: allianceTab(1, prediction.blueAlliance),
                        ),
                      ),
                    ]),
                  ]),
                ),
                drawer: hasDrawer,
              );
            }
          }),
        );
      },
    );
  }

  Widget notEnoughDataMessage() {
    return PageBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/no-notes-dark.png",
            height: 200,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Column(
              children: [
                Text(
                  "Not enough data",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  "There must be 2 or more matches recorded for each team to make a prediction.",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget allianceTab(int alliance, AllianceAnalysis allianceData) {
    return Column(children: [
      allianceData.teams.isEmpty
          ? const Text("Not enough data")
          : Row(
              children: allianceData.teams
                  .map((e) {
                    final role = e.robotRole;

                    return Flexible(
                      flex: 1,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pushNamed(
                            "/team_lookup",
                            arguments: <String, dynamic>{'team': e.team}),
                        child: Container(
                          decoration: BoxDecoration(
                              color: [
                                Theme.of(context).colorScheme.redAlliance,
                                Theme.of(context).colorScheme.blueAlliance
                              ][alliance],
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (role != null)
                                        Tooltip(
                                          message: role.name,
                                          child: Icon(role.littleEmblem),
                                        ),
                                      if (role != null)
                                        const SizedBox(width: 5),
                                      Text(
                                        e.team.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ]),
                                const SizedBox(height: 10),
                                Text(
                                  "Avg score",
                                  style: TextStyle(
                                    color: [
                                      Theme.of(context)
                                          .colorScheme
                                          .onRedAlliance,
                                      Theme.of(context)
                                          .colorScheme
                                          .onBlueAlliance
                                    ][alliance],
                                  ),
                                ),
                                Text(
                                  numToStringRounded(e.averagePoints),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList()
                  .cast<Widget>()
                  .withSpaceBetween(width: 15),
            ),
      const SizedBox(height: 15),
      Container(
        decoration: BoxDecoration(
          color: [
            Theme.of(context).colorScheme.redAlliance,
            Theme.of(context).colorScheme.blueAlliance
          ][alliance],
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Teleop points"),
              Text(
                allianceData.totalPoints == null
                    ? "--"
                    : numToStringRounded(
                        allianceData.totalPoints,
                      ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 15),
      reefStack(
        context,
        allianceData,
        backgroundColor: [
          Theme.of(context).colorScheme.onRedAlliance,
          Theme.of(context).colorScheme.onBlueAlliance
        ][alliance],
        foregroundColor: [
          Theme.of(context).colorScheme.redAlliance,
          Theme.of(context).colorScheme.blueAlliance
        ][alliance],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                value:
                    Text(numToStringRounded(allianceData.totalBallThroughput)),
                label: const Text('Total output'),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                value:
                    Text(numToStringRounded(allianceData.totalFuelOutputted)),
                label: const Text('Hub shots'),
              ),
            ),
          ].withSpaceBetween(width: 10),
        ),
      ),
    ]);
  }
}

class WinningPrediction extends StatelessWidget {
  const WinningPrediction({
    super.key,
    this.redWinning,
    this.blueWinning,
  });

  final num? redWinning;
  final num? blueWinning;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(7)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 30,
        child: (redWinning == null || blueWinning == null)
            ? Center(
                child: Text(
                  "Not enough data",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        fit: FlexFit.tight,
                        flex: (redWinning! * 100).round(),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.redAlliance),
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.tight,
                        flex: (blueWinning! * 100).round(),
                        child: Container(
                          decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.blueAlliance),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Red alliance",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${(redWinning! * 100).round()}%",
                                // style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                              )
                            ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Blue alliance",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${(blueWinning! * 100).round()}%",
                                // style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                              )
                            ]),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
