import 'dart:math';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:duration/duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup_details.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';

class TeamAutoPaths extends StatefulWidget {
  const TeamAutoPaths({
    super.key,
    required this.autoPaths,
    this.onChanged,
    this.initialSelection,
  });

  final List<AutoPath> autoPaths;
  final dynamic Function(AutoPath?)? onChanged;
  final AutoPath? initialSelection;

  @override
  State<TeamAutoPaths> createState() => _TeamAutoPathsState();
}

class _TeamAutoPathsState extends State<TeamAutoPaths>
    with TickerProviderStateMixin {
  AutoPath? selectedPath;

  bool initialized = false;

  late final AnimationController controller;
  late final AnimationController playPauseController;

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
    if (initialized == false) {
      setState(() {
        selectedPath = widget.initialSelection;
        initialized = true;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        pathDropdown(),
        if (selectedPath != null) ...[
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 3),
              child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, widget) {
                    return Column(
                      children: [
                        AutoPathField(
                          paths: [
                            AutoPathWidget(
                              animationProgress: controller.value == 0
                                  ? null
                                  : Duration(
                                      milliseconds:
                                          (controller.value * 15 * 1000)
                                              .round(),
                                    ),
                              autoPath: selectedPath!,
                              teamColor: const Color(0xFF4255F9),
                            )
                          ],
                        ),
                        AnimatedAutoPathControls(
                          controller: controller,
                          playPauseController: playPauseController,
                        ),
                      ],
                    );
                  }),
            ),
          ),
          valueBoxes(context),
          matchList(context),
        ]
      ].withSpaceBetween(height: 10),
    );
  }

  Container matchList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            "Used in matches",
            style: Theme.of(context).textTheme.titleMedium!.merge(
                  TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
          ),
          ...(selectedPath!.matches
              .map(
                (e) => Row(
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      child: Text(
                        e.getLocalizedDescription(),
                        style: Theme.of(context).textTheme.bodyMedium!.merge(
                              TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    EmphasizedContainer(
                      color: Theme.of(context).colorScheme.background,
                      padding: const EdgeInsets.fromLTRB(7, 4, 7, 4),
                      radius: 7,
                      child: Text(
                        "Score: ${numberVizualizationBuilder(selectedPath!.scores[selectedPath!.matches.indexOf(e)])}",
                        style: Theme.of(context).textTheme.bodyMedium!.merge(
                              TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              )
              .toList()
              .withSpaceBetween(height: 7)),
        ]),
      ),
    );
  }

  Row valueBoxes(BuildContext context) {
    return Row(
        children: [
      Flexible(
        flex: 1,
        fit: FlexFit.tight,
        child: valueBox(
          context,
          Text(
            numberVizualizationBuilder(
                selectedPath!.scores.cast<num>().average()),
            style: Theme.of(context).textTheme.titleLarge!.merge(
                  TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
          ),
          "Avg score",
          false,
        ),
      ),
      Flexible(
        flex: 1,
        fit: FlexFit.tight,
        child: valueBox(
          context,
          Text(
            selectedPath!.frequency.toString(),
            style: Theme.of(context).textTheme.titleLarge!.merge(
                  TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
          ),
          "Times used",
          true,
        ),
      )
    ].withSpaceBetween(width: 10));
  }

  DropdownSearch<AutoPath?> pathDropdown() {
    return DropdownSearch(
      items: widget.autoPaths,
      itemAsString: (item) => item == null ? 'None' : item.shortDescription,
      selectedItem: selectedPath,
      onChanged: (newValue) {
        controller.stop();
        controller.animateTo(0, duration: Duration.zero);

        playPauseController.reverse();

        setState(() {
          selectedPath = newValue;
        });

        if (widget.onChanged != null) {
          widget.onChanged!(newValue);
        }
      },
      popupProps: PopupProps.menu(
        constraints: BoxConstraints(
          maxHeight: min(widget.autoPaths.length * 55, 200),
        ),
        itemBuilder: (context, item, isSelected) => ListTile(
          title: Text(item?.shortDescription ?? "None"),
          trailing: item == null
              ? null
              : EmphasizedContainer(
                  padding: const EdgeInsets.fromLTRB(7, 4, 7, 4),
                  radius: 7,
                  child: Text(
                    "Score: ${numberVizualizationBuilder(item.scores.cast<num>().average())}",
                    style: Theme.of(context).textTheme.bodyMedium!.merge(
                          TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                  ),
                ),
          selected: isSelected,
          contentPadding: const EdgeInsets.only(left: 16, right: 10),
        ),
      ),
      dropdownButtonProps: selectedPath == null
          ? const DropdownButtonProps()
          : DropdownButtonProps(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  selectedPath = null;

                  if (widget.onChanged != null) {
                    widget.onChanged!(null);
                  }
                });
              },
            ),
      dropdownDecoratorProps: const DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
        label: Text("Path"),
        filled: true,
      )),
    );
  }
}

class AutoPathField extends StatelessWidget {
  const AutoPathField({
    super.key,
    required this.paths,
  });

  final List<AutoPathWidget> paths;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 522 / 489,
      child: Stack(children: [
        fieldBackground(context),
        ...paths,
      ]),
    );
  }

  Image fieldBackground(BuildContext context) {
    return Image.asset(
      "assets/images/auto_background.png",
      fit: BoxFit.cover,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
    );
  }
}

class AutoPathPainter extends CustomPainter {
  const AutoPathPainter({
    required this.color,
    required this.autoPath,
  });

  final Color color;
  final AutoPath autoPath;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    paint.color = color;
    paint.strokeWidth = 4;
    paint.strokeJoin = StrokeJoin.round;
    paint.strokeCap = StrokeCap.round;
    paint.style = PaintingStyle.stroke;

    Path path = Path();

    path.addPolygon(
      autoPath.randomizedOffsets
          .map((e) =>
              Offset((e.dx / 100) * size.width, (e.dy / 100) * size.height))
          .toList(),
      false,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class AutoPathWidget extends StatelessWidget {
  const AutoPathWidget({
    super.key,
    this.teamColor,
    required this.autoPath,
    this.animationProgress,
  });

  final Color? teamColor;
  final AutoPath autoPath;
  final Duration? animationProgress;

  @override
  Widget build(BuildContext context) {
    if (animationProgress != null) return animatedPath();
    return staticPath();
  }

  LayoutBuilder animatedPath() {
    final robotOffset = autoPath.positionAtTimestamp(animationProgress!);
    final inventory = autoPath.inventoryAtTimestamp(animationProgress!);
    final gamePieces =
        autoPath.gamePiecePositionsAtTimestamp(animationProgress!);

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Positioned(
            left: robotOffset.dx / 100 * constraints.maxWidth - 24,
            top: robotOffset.dy / 100 * constraints.maxHeight - 12,
            child: AutoPathEventIndicator(
              // width: max(24, inventory.length * 24),
              width: 48,
              teamColor: teamColor,
              isHighlighted: false,
              childBuilder: (context, teamColor, isHighlighted) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: inventory
                    .map((e) => SizedBox(
                          child: e.icon(),
                          height: 24,
                          width: 24,
                        ))
                    .toList(),
              ),
            ),
          ),
          ...(gamePieces
              .map(
                (piece) => Positioned(
                  left: piece.position.dx / 100 * constraints.maxWidth - 12,
                  top: piece.position.dy / 100 * constraints.maxHeight - 12,
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: piece.gamePiece.icon(),
                  ),
                ),
              )
              .toList())
        ],
      );
    });
  }

  LayoutBuilder staticPath() {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          CustomPaint(
            painter: AutoPathPainter(
              color: teamColor ?? Theme.of(context).colorScheme.primary,
              autoPath: autoPath,
            ),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
          ...(autoPath.randomizedOffsets
              .asMap()
              .cast<int, Offset>()
              .map((index, offset) => MapEntry(
                  index,
                  Positioned(
                    left: offset.dx / 100 * constraints.maxWidth - 12,
                    top: offset.dy / 100 * constraints.maxHeight - 12,
                    child: autoPath.timeline[index].indicator(teamColor),
                  )))
              .values),
        ],
      );
    });
  }
}

class AutoPathChargeSuccessRate {
  const AutoPathChargeSuccessRate({
    required this.dockCount,
    required this.engageCount,
    required this.failCount,
  });

  final int dockCount;
  final int engageCount;
  final int failCount;

  bool get hasAttempted => dockCount > 0 || engageCount > 0 || failCount > 0;
}

class AutoPath {
  const AutoPath({
    required this.frequency,
    required this.scores,
    required this.timeline,
    required this.matches,
  });

  final int frequency;
  final List<int> scores;
  final List<AutoPathEvent> timeline;
  final List<GameMatchIdentity> matches;

  factory AutoPath.fromMap(Map<String, dynamic> map) {
    AutoPath output = AutoPath(
      frequency: map['frequency'],
      scores: map['score'].cast<int>(),
      timeline: (map['positions'] as List<dynamic>)
          .map((e) => AutoPathEvent.fromMap(e))
          .toList(),
      matches: (map['matches'] as List<dynamic>)
          .map((e) => GameMatchIdentity.fromLongKey(
                e['matchKey'],
                tournamentName: e['tournamentName'],
              ))
          .toList(),
    );

    output.timeline.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return output;
  }

  factory AutoPath.fromMapSingleMatch(Map<String, dynamic> map) {
    AutoPath output = AutoPath(
      frequency: 1,
      scores: [map['autoPoints']],
      timeline: (map['positions'] as List<dynamic>)
          .map((e) => AutoPathEvent.fromMap(e))
          .toList(),
      matches: [GameMatchIdentity.fromLongKey(map['match'])],
    );

    output.timeline.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return output;
  }

  String get shortDescription {
    final coralCount = timeline
        .where((event) => event.type == AutoPathEventType.scoreCoral)
        .length;

    final netCount = timeline
        .where((event) => event.type == AutoPathEventType.scoreNet)
        .length;

    final processorCount = timeline
        .where((event) => event.type == AutoPathEventType.scoreProcessor)
        .length;

    bool left = timeline.any((event) => event.type == AutoPathEventType.leave);

    String name = <String>[
      if (coralCount > 0) "$coralCount Coral",
      if (processorCount > 0) "$processorCount Coral",
      if (netCount > 0) "$netCount Net",
      if (left && coralCount + netCount + processorCount == 0) "Leave",
    ].join(", ");

    name = "${{
      AutoPathLocation.startOne: "Far left",
      AutoPathLocation.startTwo: "Mid left",
      AutoPathLocation.startThree: "Mid right",
      AutoPathLocation.startFour: "Far right",
    }[timeline.first.location]} $name";

    if (name.isEmpty) name = "Nothing";

    return name;
  }

  List<Offset> get offsets => timeline.map((e) => e.offset).toList();

  List<Offset> get randomizedOffsets {
    Random random = Random(timeline.hashCode);

    List<Offset> offsets = timeline
        .map((event) => Offset(
            event.offset.dx +
                (((random.nextDouble() * 2) - 0.5) * event.randomVariance.dx),
            event.offset.dy +
                (((random.nextDouble() * 2) - 0.5) * event.randomVariance.dy)))
        .toList();

    for (var i = 0; i < offsets.length; i++) {
      final event = timeline[i];

      if (event.location == AutoPathLocation.none) {
        if (offsets.length - 1 > i) {
          offsets[i] = Offset(
            (offsets[i - 1].dx + offsets[i + 1].dx) / 2,
            (offsets[i - 1].dy + offsets[i + 1].dy) / 2,
          );
        } else {
          offsets[i] = Offset(offsets[i - 1].dx, offsets[i - 1].dy - 5);
        }
      }
    }

    return offsets;
  }

  AutoPathEvent previousEventAtTimestamp(Duration timestamp) {
    late final AutoPathEvent previousEvent;

    final progress = timestamp > timeline.last.timestamp
        ? timeline.last.timestamp
        : timestamp;

    try {
      previousEvent = timeline[
          timeline.indexWhere((event) => event.timestamp >= progress) - 1];
    } catch (e) {
      previousEvent = timeline[0];
    }

    return previousEvent;
  }

  AutoPathEvent nextEventAtTimestamp(Duration timestamp) {
    final progress = timestamp > timeline.last.timestamp
        ? timeline.last.timestamp
        : timestamp;

    final nextEvent = timeline.firstWhere(
      (event) => event.timestamp >= progress,
      orElse: () => timeline.last,
    );

    return nextEvent;
  }

  Offset positionAtTimestamp(Duration timestamp) {
    final previousEvent = previousEventAtTimestamp(timestamp);

    final progress = timestamp > timeline.last.timestamp
        ? timeline.last.timestamp
        : timestamp;

    final nextEvent = nextEventAtTimestamp(timestamp);

    final previousOffset = randomizedOffsets[timeline.indexOf(previousEvent)];
    final nextOffset = randomizedOffsets[timeline.indexOf(nextEvent)];

    double interpolationProgress =
        (progress - previousEvent.timestamp).inMilliseconds /
            (nextEvent.timestamp - previousEvent.timestamp).inMilliseconds;

    if (interpolationProgress.isNaN) {
      interpolationProgress = 0;
    }

    return Offset(
      ((nextOffset.dx - previousOffset.dx) * interpolationProgress) +
          previousOffset.dx,
      ((nextOffset.dy - previousOffset.dy) * interpolationProgress) +
          previousOffset.dy,
    );
  }

  List<GamePiece> inventoryAtTimestamp(Duration timestamp) {
    final currentTimeline =
        timeline.where((event) => event.timestamp <= timestamp);

    List<GamePiece> inventory = [];

    for (var event in currentTimeline) {
      if (event.type == AutoPathEventType.intakeAlgae) {
        inventory.add(GamePiece.algae);
      }

      if (event.type == AutoPathEventType.intakeCoral) {
        inventory.add(GamePiece.coral);
      }

      if (event.type == AutoPathEventType.scoreCoral) {
        inventory.remove(inventory.lastWhere((p) => p == GamePiece.coral));
      }

      if (event.type == AutoPathEventType.scoreNet) {
        inventory.remove(inventory.lastWhere((p) => p == GamePiece.algae));
      }

      if (event.type == AutoPathEventType.scoreProcessor) {
        inventory.remove(inventory.lastWhere((p) => p == GamePiece.algae));
      }
    }

    return inventory;
  }

  List<PositionedGamePiece> gamePiecePositionsAtTimestamp(Duration timestamp) {
    List<PositionedGamePiece> gamePieces = [];

    // Initial field
    gamePieces.addAll([
      AutoPathLocation.groundCoralA,
      AutoPathLocation.groundCoralB,
      AutoPathLocation.groundCoralC,
      AutoPathLocation.groundAlgaeA,
      AutoPathLocation.groundAlgaeB,
      AutoPathLocation.groundAlgaeC,
    ].map((location) => PositionedGamePiece(
          location.gamePiece!,
          location.offset,
        )));

    // What's there now
    final currentTimeline =
        timeline.where((event) => event.timestamp <= timestamp);

    for (var event in currentTimeline) {
      if (event.type == AutoPathEventType.intakeAlgae ||
          event.type == AutoPathEventType.intakeCoral) {
        final elementToRemove = gamePieces.cast().firstWhere(
              (element) =>
                  event.location.offset.dx == element.position.dx &&
                  event.location.offset.dy == element.position.dy &&
                  event.location.isGroundPiece &&
                  element.gamePiece == event.location.gamePiece,
              orElse: () => null,
            );

        if (elementToRemove != null) {
          gamePieces.remove(elementToRemove);
        }
      }

      if (event.type == AutoPathEventType.scoreCoral) {
        gamePieces.add(PositionedGamePiece(GamePiece.coral, event.offset));
      }
    }

    return gamePieces;
  }
}

class PositionedGamePiece {
  const PositionedGamePiece(this.gamePiece, this.position);

  final GamePiece gamePiece;
  final Offset position;
}

class AutoPathEvent {
  const AutoPathEvent({
    required this.timestamp,
    required this.type,
    required this.location,
  });

  final Duration timestamp;
  final AutoPathEventType type;
  final AutoPathLocation location;

  /// `x` and `y` are between `0` and `100`, starting from the top right of the field.
  Offset get offset => location.offset;
  Offset get randomVariance => location.randomVariance;

  factory AutoPathEvent.fromMap(Map<String, dynamic> map) => AutoPathEvent(
        timestamp: Duration(seconds: map['time']),
        type: AutoPathEventType.values[map['event']],
        location: AutoPathLocation.values[map['location']],
      );

  Widget indicator(Color? teamColor) {
    switch (type) {
      // case AutoPathEventType.dropRing:
      //   return AutoPathEventIndicator(
      //     teamColor: teamColor,
      //     childBuilder: (context, teamColor, isHighlighted) =>
      //         iconAutoPathEventIndicator(
      //       context,
      //       teamColor,
      //       isHighlighted,
      //       CupertinoIcons.bag_badge_minus,
      //     ),
      //   );
      // case AutoPathEventType.pickUp:
      //   return AutoPathEventIndicator(
      //     teamColor: teamColor,
      //     childBuilder: (context, teamColor, isHighlighted) =>
      //         iconAutoPathEventIndicator(
      //       context,
      //       teamColor,
      //       isHighlighted,
      //       CupertinoIcons.bag_badge_plus,
      //     ),
      //   );
      // case AutoPathEventType.score:
      //   return AutoPathEventIndicator(
      //     teamColor: teamColor,
      //     childBuilder: (context, teamColor, isHighlighted) =>
      //         iconAutoPathEventIndicator(
      //       context,
      //       teamColor,
      //       isHighlighted,
      //       Icons.sports_score,
      //     ),
      //   );
      default:
        return Container();
    }
  }
}

class AnimatedAutoPathControls extends StatelessWidget {
  const AnimatedAutoPathControls({
    super.key,
    required this.controller,
    required this.playPauseController,
  });

  final AnimationController controller;
  final AnimationController playPauseController;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            if (controller.isAnimating) {
              controller.stop();
              playPauseController.reverse();
            } else {
              controller.forward(from: controller.value == 1 ? 0 : null);

              playPauseController.forward();
            }
          },
          icon: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: playPauseController,
          ),
          tooltip: playPauseController.value > 0.5 ? 'Pause' : 'Play',
        ),
        Expanded(
          child: Slider(
            value: controller.value,
            onChanged: (value) {
              controller.stop();

              playPauseController.reverse();

              controller.animateTo(value, duration: Duration.zero);
            },
            min: 0,
            max: 1,
            inactiveColor: Theme.of(context).colorScheme.background,
          ),
        ),
        Text(prettyDuration(
          Duration(
            milliseconds: (controller.value * 15 * 1000).round(),
          ),
          abbreviated: true,
        ))
      ],
    );
  }
}

enum AutoPathEventType {
  intakeCoral,
  intakeAlgae,
  unused2,
  leave,
  unused4,
  scoreNet,
  unused6,
  scoreProcessor,
  scoreCoral,
  unused9,
  unused10,
  startMatch,
}

enum GamePiece {
  coral,
  algae,
}

extension GamePieceExtension on GamePiece {
  Widget icon({Color color = Colors.white}) {
    switch (this) {
      case GamePiece.coral:
        return Transform.scale(
            scale: 2 / 3,
            child: SvgPicture.asset(
              'assets/images/frc_coral.svg',
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              height: 16,
              width: 16,
            ));
      case GamePiece.algae:
        return Transform.scale(
            scale: 2 / 3,
            child: SvgPicture.asset(
              'assets/images/frc_algae.svg',
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              height: 16,
              width: 16,
            ));
    }
  }
}

class AutoPathEventIndicator extends StatelessWidget {
  const AutoPathEventIndicator({
    super.key,
    required this.childBuilder,
    this.isHighlighted = false,
    this.teamColor,
    this.width = 24,
    this.height = 24,
  });

  final Color? teamColor;
  final bool isHighlighted;
  final Widget Function(
    BuildContext context,
    Color? teamColor,
    bool isHighlighted,
  ) childBuilder;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          color: isHighlighted
              ? Colors.white
              : teamColor ?? Theme.of(context).colorScheme.primaryContainer,
        ),
        child: childBuilder(context, teamColor, isHighlighted),
      ),
    );
  }
}

Widget iconAutoPathEventIndicator(
  BuildContext context,
  Color? teamColor,
  bool isHighlighted,
  IconData icon,
) =>
    Icon(
      icon,
      size: 16,
      color: isHighlighted
          ? teamColor ?? Theme.of(context).colorScheme.primary
          : Colors.white,
    );

enum AutoPathLocation {
  none,

  /// LO - LI based on [this](https://github.com/HighlanderRobotics/Reefscape/blob/main/notes/leftStartingLabels.PNG)
  startOne,

  /// LI - LM based on [this](https://github.com/HighlanderRobotics/Reefscape/blob/main/notes/leftStartingLabels.PNG)
  startTwo,

  /// RM - RI based on [this](https://github.com/HighlanderRobotics/Reefscape/blob/main/notes/leftStartingLabels.PNG)
  startThree,

  /// RI - RO based on [this](https://github.com/HighlanderRobotics/Reefscape/blob/main/notes/leftStartingLabels.PNG)
  startFour,

  reefL1,
  reefL2,
  reefL3,
  reefL4,

  reefL1A,
  reefL1B,
  reefL1C,

  reefL2A,
  reefL2B,
  reefL2C,

  reefL3A,
  reefL3B,
  reefL3C,

  reefL4A,
  reefL4B,
  reefL4C,

  groundCoralA,
  groundCoralB,
  groundCoralC,

  coralStationOne,
  coralStationTwo,

  groundAlgaeA,
  groundAlgaeB,
  groundAlgaeC,
}

extension AutoPathLocationExtension on AutoPathLocation {
  /// `x` and `y` are between `0` and `100`, starting from the top right of the field.
  Offset get offset {
    switch (this) {
      case AutoPathLocation.startOne:
        return const Offset(13.5, 85);
      case AutoPathLocation.startTwo:
        return const Offset(13.5, 65);
      case AutoPathLocation.startThree:
        return const Offset(13.5, 35);
      case AutoPathLocation.startFour:
        return const Offset(13.5, 15);
      case AutoPathLocation.reefL1:
      case AutoPathLocation.reefL2:
      case AutoPathLocation.reefL3:
      case AutoPathLocation.reefL4:
        return const Offset(48.3, 50.2);
      case AutoPathLocation.reefL1A:
      case AutoPathLocation.reefL2A:
      case AutoPathLocation.reefL3A:
      case AutoPathLocation.reefL4A:
        return const Offset(56, 42.7);
      case AutoPathLocation.reefL1B:
      case AutoPathLocation.reefL2B:
      case AutoPathLocation.reefL3B:
      case AutoPathLocation.reefL4B:
        return const Offset(56, 58);
      case AutoPathLocation.reefL1C:
      case AutoPathLocation.reefL2C:
      case AutoPathLocation.reefL3C:
      case AutoPathLocation.reefL4C:
        return const Offset(39.5, 50.2);
      case AutoPathLocation.groundAlgaeA:
        return const Offset(85.2 + 3, 71.9);
      case AutoPathLocation.groundAlgaeB:
        return const Offset(85.2 + 3, 50);
      case AutoPathLocation.groundAlgaeC:
        return const Offset(85.2 + 3, 28.1);
      case AutoPathLocation.groundCoralA:
        return const Offset(85.2 - 3, 71.9);
      case AutoPathLocation.groundCoralB:
        return const Offset(85.2 - 3, 50);
      case AutoPathLocation.groundCoralC:
        return const Offset(85.2 - 3, 28.1);
      case AutoPathLocation.coralStationOne:
        return const Offset(89, 90);
      case AutoPathLocation.coralStationTwo:
        return const Offset(89, 10);
      default:
        return const Offset(0, 0);
    }
  }

  Offset get randomVariance {
    switch (this) {
      default:
        return const Offset(0, 0);
    }
  }

  bool get isGroundPiece => [
        AutoPathLocation.groundCoralA,
        AutoPathLocation.groundCoralB,
        AutoPathLocation.groundCoralC,
        AutoPathLocation.groundAlgaeA,
        AutoPathLocation.groundAlgaeB,
        AutoPathLocation.groundAlgaeC,
      ].contains(this);

  GamePiece? get gamePiece {
    switch (this) {
      case AutoPathLocation.groundCoralA:
        return GamePiece.coral;
      case AutoPathLocation.groundCoralB:
        return GamePiece.coral;
      case AutoPathLocation.groundCoralC:
        return GamePiece.coral;
      case AutoPathLocation.groundAlgaeA:
        return GamePiece.algae;
      case AutoPathLocation.groundAlgaeB:
        return GamePiece.algae;
      case AutoPathLocation.groundAlgaeC:
        return GamePiece.algae;
      default:
        return null;
    }
  }
}
