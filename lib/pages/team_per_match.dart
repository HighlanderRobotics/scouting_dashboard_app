import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/alliance.dart';
import 'package:scouting_dashboard_app/reusable/color_combination.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_dashboard_app/reusable/value_tile.dart';

class TeamPerMatchArgs {
  TeamPerMatchArgs({
    required this.longMatchKey,
    required this.teamNumber,
  });

  String longMatchKey;
  int teamNumber;
}

class NoteData {
  const NoteData({
    required this.body,
    required this.uuid,
    required this.match,
    required this.author,
  });

  final String body;
  final String uuid;
  final GameMatchIdentity match;
  final String author;

  /// From a JSON-derived map in the format:
  /// ```json
  /// {
  ///   "notes": "Body",
  ///   "uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  ///   "matchNum": 1,
  ///   "matchKey": "20XXtournament_qm1_0",
  ///   "scouterName": "Firstname Lastname"
  /// }
  /// ```
  factory NoteData.fromJson(Map<String, dynamic> json) {
    return NoteData(
      body: json['notes'],
      uuid: json['uuid'],
      match: GameMatchIdentity.fromLongKey(json['matchKey']),
      author: json['scouterName'],
    );
  }
}

class TeamPerMatchResponse {
  const TeamPerMatchResponse({
    required this.autoScore,
    this.autoPath,
    required this.driverAbility,
    required this.role,
    required this.notes,
    required this.teleopScore,

    // Season-specific
    required this.levelOneCones,
    required this.levelTwoCones,
    required this.levelThreeCones,
    required this.levelOneCubes,
    required this.levelTwoCubes,
    required this.levelThreeCubes,
  });

  final int autoScore;
  final AutoPath? autoPath;

  final int driverAbility;
  final RobotRole role;
  final List<NoteData> notes;
  final int teleopScore;

  // Season-specific
  final int levelOneCones;
  final int levelTwoCones;
  final int levelThreeCones;

  final int levelOneCubes;
  final int levelTwoCubes;
  final int levelThreeCubes;

  /// Create from a decoded JSON array in the format of a `/API/analysis/teamAndMatch` server response
  factory TeamPerMatchResponse.fromJson(List<dynamic> json) {
    Map<String, dynamic> metrics = json[0]['result']['metrics'];

    return TeamPerMatchResponse(
      autoScore: metrics['autoScore']['value'],
      autoPath: metrics['autoPath'] == null
          ? null
          : AutoPath.fromMap(metrics['autoPath']),
      driverAbility: metrics['driverAbility'],
      role: RobotRole.values[metrics['role']],
      notes: (metrics['notes'] as List<dynamic>)
          .map((n) => NoteData.fromJson(n))
          .toList(),
      teleopScore: metrics['teleScore'],
      levelOneCones: metrics['levelOneCone'],
      levelTwoCones: metrics['levelTwoCone'],
      levelThreeCones: metrics['levelThreeCone'],
      levelOneCubes: metrics['levelOneCube'],
      levelTwoCubes: metrics['levelTwoCube'],
      levelThreeCubes: metrics['levelThreeCube'],
    );
  }

  static Future<TeamPerMatchResponse?> fromServer({
    required int team,
    required String longMatchKey,
  }) async {
    final authority = (await getServerAuthority())!;

    final response = await http.get(
      Uri.http(authority, '/API/analysis/teamAndMatch', {
        'team': team.toString(),
        'matchKey': longMatchKey,
      }),
    );

    if (response.statusCode != 200) {
      throw "Server responded with a status of ${response.statusCode}";
    }

    if (jsonDecode(response.body)[0]['result'] == null) {
      return null;
    }

    return TeamPerMatchResponse.fromJson(jsonDecode(response.body));
  }

  Map<String, dynamic> get cargoStackAnalysisMap => {
        'totalPoints': autoScore + teleopScore,
        'levelCargo': [
          {
            'cones': levelOneCones,
            'cubes': levelOneCubes,
          },
          {
            'cones': levelTwoCones,
            'cubes': levelTwoCubes,
          },
          {
            'cones': levelThreeCones,
            'cubes': levelThreeCubes,
          },
        ]
      };
}

class TeamPerMatchPage extends StatefulWidget {
  const TeamPerMatchPage({super.key});

  @override
  State<TeamPerMatchPage> createState() => _TeamPerMatchPageState();
}

class _TeamPerMatchPageState extends State<TeamPerMatchPage> {
  TeamPerMatchResponse? analysisData;
  bool loaded = false;
  String? error;

  bool renderedOnce = false;

  Future<void> loadData(TeamPerMatchArgs args) async {
    try {
      final data = await TeamPerMatchResponse.fromServer(
        team: args.teamNumber,
        longMatchKey: args.longMatchKey,
      );

      setState(() {
        loaded = true;
        analysisData = data;
      });
    } catch (err) {
      setState(() {
        loaded = true;
        error = err.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as TeamPerMatchArgs;

    final match = GameMatchIdentity.fromLongKey(args.longMatchKey);
    final team = args.teamNumber;

    if (renderedOnce == false) {
      loadData(args);

      setState(() {
        renderedOnce = true;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("$team in ${match.getShortLocalizedDescription()}"),
      ),
      body: loaded ? loadedView(args) : loadingView(),
    );
  }

  // TODO: Replace with skeleton
  Widget loadingView() => const Center(child: CircularProgressIndicator());

  Widget loadedView(TeamPerMatchArgs args) {
    if (error != null) {
      return Center(
        child: FriendlyErrorView(
          errorMessage: error,
          onRetry: () {
            setState(() {
              analysisData = null;
              loaded = false;
              error = null;
            });

            loadData(args);
          },
        ),
      );
    }

    if (analysisData == null) {
      return const Center(
        child: Text("No data is available."),
      );
    }

    return TeamPerMatchVizualization(args: args, analysis: analysisData!);
  }
}

class TeamPerMatchVizualization extends StatelessWidget {
  const TeamPerMatchVizualization({
    super.key,
    required this.args,
    required this.analysis,
  });

  final TeamPerMatchArgs args;
  final TeamPerMatchResponse analysis;

  @override
  Widget build(BuildContext context) {
    return ScrollablePageBody(
      children: [
        roleDriverAbilityRow(context),
        headline(context, "Score"),
        scoreRow(),
        if (analysis.autoPath != null) ...[
          headline(context, "Auto"),
          autoPath(context),
        ],
        headline(context, "Teleop"),
        cargoStack(
          context,
          analysis.cargoStackAnalysisMap,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
        if (analysis.notes.isNotEmpty) ...[
          headline(context, "Notes"),
          notesList(context),
        ],
      ].withSpaceBetween(height: 10),
    );
  }

  Column notesList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: analysis.notes
          .map((note) => EmphasizedContainer(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      note.author,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      note.body,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ))
          .toList()
          .withSpaceBetween(height: 10),
    );
  }

  IntrinsicHeight roleDriverAbilityRow(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: roleVizualization(context),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: driverAbilityVizualization(context),
          ),
        ].withSpaceBetween(width: 10),
      ),
    );
  }

  Widget autoPath(BuildContext context) {
    return Column(
      children: [
        // AnimatedAutoPath(analysis: analysis),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueTile(
                value: Text(analysis.autoPath!.scores
                    .reduce(
                        (value, element) => element > value ? element : value)
                    .toString()),
                label: const Text("Max score"),
                colorCombination: ColorCombination.emphasis,
              ),
              Flexible(
                fit: FlexFit.tight,
                child: GestureDetector(
                  onTap: () {
                    showDialog(context: context, builder: autoPathUsageDialog);
                  },
                  child: EmphasizedContainer(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Path used in ${analysis.autoPath!.frequency} match${analysis.autoPath!.frequency == 1 ? '' : 'es'}",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ].withSpaceBetween(width: 10),
          ),
        ),
      ].withSpaceBetween(height: 10),
    );
  }

  Widget autoPathUsageDialog(BuildContext context) {
    AutoPath path = analysis.autoPath!;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Used ${path.frequency} times",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const CloseButton(),
              ],
            ),
            EmphasizedContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: path.matches
                    .map((match) => Text(
                          match.getLocalizedDescription(
                              includeTournament: false),
                        ))
                    .toList(),
              ),
            ),
            Text(
              "Scores",
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            EmphasizedContainer(
              child: Text(path.scores.join(', ')),
            ),
          ].withSpaceBetween(height: 10),
        ),
      ),
    );
  }

  Row scoreRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          fit: FlexFit.tight,
          child: ValueTile(
            value: Text(analysis.autoScore.toString()),
            label: const Text("Auto"),
            colorCombination: ColorCombination.colored,
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          child: ValueTile(
            value: Text(analysis.teleopScore.toString()),
            label: const Text("Teleop"),
            colorCombination: ColorCombination.colored,
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          child: ValueTile(
            value: Text((analysis.autoScore + analysis.teleopScore).toString()),
            label: const Text("Total"),
            colorCombination: ColorCombination.emphasis,
          ),
        ),
      ].withSpaceBetween(width: 10),
    );
  }

  Widget headline(BuildContext context, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          text,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  EmphasizedContainer roleVizualization(BuildContext context) {
    return EmphasizedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Role",
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                analysis.role.littleEmblem,
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                analysis.role.name,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          )
        ],
      ),
    );
  }

  EmphasizedContainer driverAbilityVizualization(BuildContext context) {
    return EmphasizedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Driver ability",
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            "${analysis.driverAbility}/5",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        ],
      ),
    );
  }
}

class AnimatedAutoPath extends StatefulWidget {
  const AnimatedAutoPath({
    super.key,
    required this.analysis,
  });

  final SingleScoutReportAnalysis analysis;

  @override
  State<AnimatedAutoPath> createState() => _AnimatedAutoPathState();
}

class _AnimatedAutoPathState extends State<AnimatedAutoPath>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  late final AnimationController playPauseController;

  bool playing = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    playPauseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    controller.addListener(() {
      if (controller.value == 1) {
        playPauseController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, widget) {
        debugPrint(controller.duration.toString());
        return EmphasizedContainer(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 3),
          child: Column(
            children: [
              AutoPathField(paths: [
                AutoPathWidget(
                  animationProgress: controller.value == 0
                      ? null
                      : Duration(
                          milliseconds: (controller.value * 15 * 1000).round(),
                        ),
                  autoPath: analysis.autoPath!,
                  teamColor: Colors.blue[700],
                ),
              ]),
              AnimatedAutoPathControls(
                controller: controller,
                playPauseController: playPauseController,
              ),
            ],
          ),
        );
      },
    );
  }
}
