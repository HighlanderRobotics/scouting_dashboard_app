import 'dart:convert';

import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/pages/alliance.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';

class MatchSuggestionsPage extends StatefulWidget {
  const MatchSuggestionsPage({super.key});

  @override
  State<MatchSuggestionsPage> createState() => _MatchSuggestionsPageState();
}

class _MatchSuggestionsPageState extends State<MatchSuggestionsPage> {
  Future<Map<String, dynamic>> getSuggestions({
    required MatchType matchType,
    required Map<String, int> teams,
  }) async {
    final authority = (await getServerAuthority())!;

    final response =
        await http.get(Uri.http(authority, '/API/analysis/suggestions', {
      ...teams.map((key, value) => MapEntry(key, value.toString())),
      'matchType': matchType.shortName,
    }));

    if (response.statusCode != 200) {
      throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
    }

    return jsonDecode(response.body)[0];
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    GameMatchIdentity? matchIdentity = routeArgs['matchIdentity'];
    MatchType matchType =
        matchIdentity != null ? matchIdentity.type : routeArgs['matchType'];

    Map<String, int> teams = routeArgs['teams'];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                matchIdentity == null
                    ? "Match Suggestions (${matchType.shortName.toUpperCase()})"
                    : "Suggestions for ${matchIdentity.getShortLocalizedDescription()}",
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Text(
                    "Beta",
                    style: Theme.of(context).textTheme.labelMedium!.merge(
                          TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary),
                        ),
                  ),
                ),
              )
            ].withSpaceBetween(width: 10),
          ),
          bottom: const TabBar(tabs: [
            Text("Red"),
            Text("Blue"),
          ]),
        ),
        body: FutureBuilder(
          future: (() async =>
              getSuggestions(matchType: matchType, teams: teams))(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return PageBody(
                child: Center(
                  child: Text(
                    "Encountered an error getting suggestions: ${snapshot.error}",
                  ),
                ),
              );
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return const PageBody(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    LinearProgressIndicator(),
                  ],
                ),
              );
            }

            return TabBarView(children: [
              allianceSuggestions("red", snapshot.data!),
              allianceSuggestions("blue", snapshot.data!),
            ]);
          },
        ),
      ),
    );
  }

  Widget allianceSuggestions(String alliance, Map<String, dynamic> data) {
    return ScrollablePageBody(
        children: [
      teamsRow(data, alliance),
      suggestedAutoPaths(data, alliance),
      teleopSuggestions(alliance, data),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: alliance == 'red'
                  ? Theme.of(context).colorScheme.redAlliance
                  : Theme.of(context).colorScheme.blueAlliance,
              padding: const EdgeInsets.all(10),
              child: const Text("Endgame"),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                  children: (data["${alliance}Alliance"]['endgame']
                          as List<dynamic>)
                      .map((team) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(team['team']),
                              Text(
                                prettyDuration(
                                  Duration(seconds: team['time'].round()),
                                ),
                              ),
                            ],
                          ))
                      .toList()),
            ),
          ],
        ),
      )
    ].withSpaceBetween(height: 10));
  }

  Container teleopSuggestions(String alliance, Map<String, dynamic> data) {
    List<GridColor> positions = [];

    for (var team in data['${alliance}Alliance']['teleop'] as List<dynamic>) {
      for (var item in (team['scoringGrid'] ?? []).where((e) => e != null)) {
        positions.add(
          GridColor(
            color: gridSuggestionsColors[
                (data['${alliance}Alliance']['teleop'] as List<dynamic>)
                    .indexWhere((e) => e['team'] == team['team'])],
            position: GridPosition.values[item],
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: alliance == 'red'
                ? Theme.of(context).colorScheme.redAlliance
                : Theme.of(context).colorScheme.blueAlliance,
            padding: const EdgeInsets.all(10),
            child: const Text("Teleop"),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      (data["${alliance}Alliance"]['teleop'] as List<dynamic>)
                          .map((team) => Row(children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      color: gridSuggestionsColors[
                                          (data["${alliance}Alliance"]['teleop']
                                                  as List<dynamic>)
                                              .indexWhere((e) =>
                                                  e['team'] == team['team'])],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  team['team'],
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
                                )
                              ]))
                          .toList(),
                ),
                const SizedBox(height: 10),
                GridSuggestions(positions: positions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container suggestedAutoPaths(Map<String, dynamic> data, String alliance) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: alliance == "red"
                  ? Theme.of(context).colorScheme.redAlliance
                  : Theme.of(context).colorScheme.blueAlliance,
            ),
            padding: const EdgeInsets.all(10),
            child: const Text("Auto"),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                allianceAutoPathsLegend(data, alliance),
                AutoPathField(
                  paths: data["${alliance}Alliance"]['auto']
                      .where((e) => e['path'].isNotEmpty as bool)
                      .map(
                        (team) => AutoPathWidget(
                          autoPath: AutoPath.fromMap(team['path']),
                          teamColor: autoPathColors[(data["${alliance}Alliance"]
                                  ['auto'] as List<dynamic>)
                              .indexWhere((e) => e['team'] == team['team'])],
                        ),
                      )
                      .toList()
                      .cast<AutoPathWidget>(),
                ),
              ].withSpaceBetween(height: 10),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: alliance == "red"
                  ? Theme.of(context).colorScheme.onRedAlliance
                  : Theme.of(context).colorScheme.onBlueAlliance,
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Auto points",
                  style: Theme.of(context).textTheme.labelLarge!.merge(
                        TextStyle(
                          color: alliance == "red"
                              ? Theme.of(context).colorScheme.redAlliance
                              : Theme.of(context).colorScheme.blueAlliance,
                        ),
                      ),
                ),
                Text(
                  numberVizualizationBuilder((data['${alliance}Alliance']
                          ['auto'] as List<dynamic>)
                      .where((e) => e['path'].isNotEmpty)
                      .map((e) =>
                          ((e['path']['score'] as List<dynamic>).cast<num>())
                              .average())
                      .toList()
                      .sum()),
                  style: Theme.of(context).textTheme.bodyMedium!.merge(
                        TextStyle(
                          color: alliance == "red"
                              ? Theme.of(context).colorScheme.redAlliance
                              : Theme.of(context).colorScheme.blueAlliance,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Row allianceAutoPathsLegend(Map<String, dynamic> data, String alliance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: (data["${alliance}Alliance"]['auto'] as List<dynamic>)
          .map((team) => InkWell(
                onTap: team['path'].isEmpty
                    ? null
                    : () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              AutoPath path = AutoPath.fromMap(team['path']);

                              return AlertDialog(
                                title: Text("${team['team']}'s suggested path"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            path.scores.length == 1
                                                ? "Score"
                                                : "Scores",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge!
                                                .merge(
                                                  TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                                ),
                                          ),
                                          Text(
                                            path.scores.join(", "),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .merge(
                                                  TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            "Used in matches",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge!
                                                .merge(
                                                  TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                          ),
                                          ...path.matches
                                              .map(
                                                (e) => Text(
                                                  e.getLocalizedDescription(
                                                    includeTournament: false,
                                                  ),
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              )
                                              .toList()
                                        ],
                                      ),
                                    ),
                                    if (path.chargeSuccessRate.hasAttempted)
                                      ClipRRect(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        child: Row(children: [
                                          Flexible(
                                            fit: FlexFit.tight,
                                            flex: path
                                                .chargeSuccessRate.dockCount,
                                            child: Container(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      path.chargeSuccessRate
                                                          .dockCount
                                                          .toString(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelLarge!
                                                          .merge(TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onPrimary)),
                                                    ),
                                                    Text(
                                                      "docks",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium!
                                                          .merge(TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onPrimary)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            fit: FlexFit.tight,
                                            flex: path
                                                .chargeSuccessRate.engageCount,
                                            child: Container(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      path.chargeSuccessRate
                                                          .engageCount
                                                          .toString(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelLarge!
                                                          .merge(TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer)),
                                                    ),
                                                    Text(
                                                      "engages",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium!
                                                          .merge(TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            fit: FlexFit.tight,
                                            flex: path
                                                .chargeSuccessRate.failCount,
                                            child: Container(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      path.chargeSuccessRate
                                                          .failCount
                                                          .toString(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelLarge!
                                                          .merge(TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onError)),
                                                    ),
                                                    Text(
                                                      "fails",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium!
                                                          .merge(TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onError)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                      ),
                                  ].withSpaceBetween(height: 10),
                                ),
                                actions: [
                                  FilledButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Done"),
                                  ),
                                ],
                              );
                            });
                      },
                child: Row(children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        color: autoPathColors[(data["${alliance}Alliance"]
                                ['auto'] as List<dynamic>)
                            .indexWhere((e) => e['team'] == team['team'])],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    team['team'],
                    style: Theme.of(context).textTheme.labelMedium!.merge(
                          TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                  )
                ]),
              ))
          .toList(),
    );
  }

  Row teamsRow(Map<String, dynamic> data, String alliance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: data["${alliance}Alliance"]['teleop']
          .map((team) => Row(
                children: [
                  Tooltip(
                    message: RobotRole.values[team['role']].name,
                    child: Icon(RobotRole.values[team['role']].littleEmblem),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed("/team_lookup",
                          arguments: <String, dynamic>{
                            'team': int.parse(team['team']),
                          });
                    },
                    child: Text(
                      team['team'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ].withSpaceBetween(width: 4),
              ))
          .toList()
          .cast<Widget>(),
    );
  }
}

class GridColor {
  const GridColor({
    required this.color,
    required this.position,
  });

  final Color color;
  final GridPosition position;
}

class GridSuggestions extends StatelessWidget {
  const GridSuggestions({
    super.key,
    required this.positions,
  });

  final List<GridColor> positions;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1075 / 271,
      child: LayoutBuilder(
          builder: (context, constraints) => Stack(children: [
                Image.asset('assets/images/grid.png'),
                ...positions.map(
                  (i) => Positioned(
                    left: (i.position.positionBounds[0].dx / 100) *
                        constraints.maxWidth,
                    top: (i.position.positionBounds[0].dy / 100) *
                        constraints.maxHeight,
                    child: SizedBox(
                      height: ((i.position.positionBounds[1].dy -
                                  i.position.positionBounds[0].dy) /
                              100) *
                          constraints.maxHeight,
                      width: ((i.position.positionBounds[1].dx -
                                  i.position.positionBounds[0].dx) /
                              100) *
                          constraints.maxWidth,
                      child: Container(
                        color: i.color.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ])),
    );
  }
}

const gridSuggestionsColors = <Color>[
  Colors.red,
  Colors.yellow,
  Colors.blue,
];

enum GridPosition {
  none,
  bumpsideL1,
  middleL1,
  clearsideL1,
  bumpsideL2,
  middleL2,
  clearsideL2,
  bumpsideL3,
  middleL3,
  clearsideL3,
}

extension GridPositionExtension on GridPosition {
  List<Offset> get positionBounds {
    switch (this) {
      case GridPosition.bumpsideL1:
        return [
          const Offset(66, 67),
          const Offset(100, 100),
        ];
      case GridPosition.middleL1:
        return [
          const Offset(35, 67),
          const Offset(66, 100),
        ];
      case GridPosition.clearsideL1:
        return [
          const Offset(0, 67),
          const Offset(35, 100),
        ];
      case GridPosition.bumpsideL2:
        return [
          const Offset(66, 36),
          const Offset(100, 67),
        ];
      case GridPosition.middleL2:
        return [
          const Offset(35, 36),
          const Offset(66, 67),
        ];
      case GridPosition.clearsideL2:
        return [
          const Offset(0, 36),
          const Offset(35, 67),
        ];
      case GridPosition.bumpsideL3:
        return [
          const Offset(66, 0),
          const Offset(100, 36),
        ];
      case GridPosition.middleL3:
        return [
          const Offset(35, 0),
          const Offset(66, 36),
        ];
      case GridPosition.clearsideL3:
        return [
          const Offset(0, 0),
          const Offset(35, 36),
        ];
      default:
        return [
          const Offset(0, 0),
          const Offset(0, 0),
        ];
    }
  }
}
