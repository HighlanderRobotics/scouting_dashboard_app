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
          if (selectedPath!.chargeSuccessRate.hasAttempted)
            ChargeSuccessBreakdown(path: selectedPath),
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
          ...(selectedPath!.matches.map((e) => Text(
                e.getLocalizedDescription(includeTournament: false),
                style: Theme.of(context).textTheme.bodyMedium!.merge(
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
              ))),
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
          selectedPath!.scores.length == 1 ? "Score" : "Scores",
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

class ChargeSuccessBreakdown extends StatelessWidget {
  const ChargeSuccessBreakdown({
    super.key,
    required this.path,
  });

  final AutoPath? path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: Row(children: [
        Flexible(
          fit: FlexFit.tight,
          flex: path!.chargeSuccessRate.dockCount,
          child: Container(
            color: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path!.chargeSuccessRate.dockCount.toString(),
                    style: Theme.of(context).textTheme.titleLarge!.merge(
                        TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary)),
                  ),
                  Text(
                    "docks",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          flex: path!.chargeSuccessRate.engageCount,
          child: Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path!.chargeSuccessRate.engageCount.toString(),
                    style: Theme.of(context).textTheme.titleLarge!.merge(
                        TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer)),
                  ),
                  Text(
                    "engages",
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          flex: path!.chargeSuccessRate.failCount,
          child: Container(
            color: Theme.of(context).colorScheme.error,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path!.chargeSuccessRate.failCount.toString(),
                    style: Theme.of(context).textTheme.titleLarge!.merge(
                        TextStyle(
                            color: Theme.of(context).colorScheme.onError)),
                  ),
                  Text(
                    "fails",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.onError),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
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
      aspectRatio: 688 / 480,
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
            left: robotOffset.dx / 100 * constraints.maxWidth - 12,
            top: robotOffset.dy / 100 * constraints.maxHeight - 12,
            child: AutoPathEventIndicator(
              teamColor: teamColor,
              isHighlighted: false,
              childBuilder: (context, teamColor, isHighlighted) =>
                  inventory.isEmpty ? Container() : inventory.last.icon(),
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
    required this.chargeSuccessRate,
  });

  final int frequency;
  final List<int> scores;
  final List<AutoPathEvent> timeline;
  final List<GameMatchIdentity> matches;

  final AutoPathChargeSuccessRate chargeSuccessRate;

  factory AutoPath.fromMap(Map<String, dynamic> map) {
    AutoPath output = AutoPath(
      frequency: map['frequency'],
      scores: map['score'].cast<int>(),
      timeline: (map['positions'] as List<dynamic>)
          .map((e) => AutoPathEvent.fromMap(e))
          .toList(),
      matches: (map['matches'] as List<dynamic>)
          .map((e) => GameMatchIdentity.fromLongKey(e))
          .toList(),
      chargeSuccessRate: AutoPathChargeSuccessRate(
        dockCount: map['chargeRate']['docked'],
        engageCount: map['chargeRate']['engaged'],
        failCount: map['chargeRate']['failed'],
      ),
    );

    output.timeline.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return output;
  }

  String get shortDescription {
    final coneCount = timeline
        .where((event) => event.type == AutoPathEventType.placeCone)
        .length;

    final cubeCount = timeline
        .where((event) => event.type == AutoPathEventType.placeCube)
        .length;

    bool didCharge =
        timeline.any((e) => e.type == AutoPathEventType.chargeStation);

    bool leftCommunity = timeline
        .any((event) => event.type == AutoPathEventType.crossCommunityBorder);

    String name = <String>[
      if (leftCommunity) "Mobility",
      if (coneCount > 0) "$coneCount Cone",
      if (cubeCount > 0) "$cubeCount Cube",
      if (didCharge) "Charger",
    ].join(", ");

    name = "${{
      AutoPathLocation.communityCenter1: "Bump-side",
      AutoPathLocation.communityCenter2: "Middle",
      AutoPathLocation.communityCenter3: "Clear-side",
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
      if (event.type == AutoPathEventType.pickUpCube) {
        inventory.add(GamePiece.cube);
      }

      if (event.type == AutoPathEventType.pickUpCone) {
        inventory.add(GamePiece.cone);
      }

      if (event.type == AutoPathEventType.placeCone) {
        inventory.remove(
          inventory.lastWhere((piece) => piece == GamePiece.cone),
        );
      }

      if (event.type == AutoPathEventType.placeCube) {
        inventory.remove(
          inventory.lastWhere((piece) => piece == GamePiece.cube),
        );
      }

      if (event.type == AutoPathEventType.dropItem) {
        inventory.remove(inventory.last);
      }
    }

    return inventory;
  }

  List<PositionedGamePiece> gamePiecePositionsAtTimestamp(Duration timestamp) {
    List<PositionedGamePiece> gamePieces = [];

    // Initial field
    for (var event in timeline) {
      if (event.type == AutoPathEventType.pickUpCone) {
        gamePieces.add(PositionedGamePiece(
            GamePiece.cone, randomizedOffsets[timeline.indexOf(event)]));
      }

      if (event.type == AutoPathEventType.pickUpCube) {
        gamePieces.add(PositionedGamePiece(
            GamePiece.cube, randomizedOffsets[timeline.indexOf(event)]));
      }
    }

    // What's there now
    final currentTimeline =
        timeline.where((event) => event.timestamp <= timestamp);

    for (var event in currentTimeline) {
      if ([AutoPathEventType.pickUpCone, AutoPathEventType.pickUpCube]
          .contains(event.type)) {
        gamePieces.remove(
          gamePieces.firstWhere(
            (piece) =>
                piece.position == randomizedOffsets[timeline.indexOf(event)],
          ),
        );
      }

      if (event.type == AutoPathEventType.placeCube) {
        gamePieces.add(
          PositionedGamePiece(
            GamePiece.cube,
            randomizedOffsets[timeline.indexOf(event)],
          ),
        );
      }

      if (event.type == AutoPathEventType.placeCone) {
        gamePieces.add(
          PositionedGamePiece(
            GamePiece.cone,
            randomizedOffsets[timeline.indexOf(event)],
          ),
        );
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
      case AutoPathEventType.dropItem:
        return AutoPathEventIndicator(
          teamColor: teamColor,
          childBuilder: (context, teamColor, isHighlighted) =>
              iconAutoPathEventIndicator(
            context,
            teamColor,
            isHighlighted,
            CupertinoIcons.bag_badge_minus,
          ),
        );
      case AutoPathEventType.startWithoutItem:
        return AutoPathEventIndicator(
          childBuilder: (context, teamColor, isHighlighted) =>
              iconAutoPathEventIndicator(
            context,
            teamColor,
            isHighlighted,
            Icons.play_arrow_outlined,
          ),
          isHighlighted: true,
          teamColor: teamColor,
        );
      case AutoPathEventType.pickUpCone:
        return AutoPathEventIndicator(
          isHighlighted: [
            AutoPathLocation.communityCenter1,
            AutoPathLocation.communityCenter2,
            AutoPathLocation.communityCenter3,
          ].contains(location),
          teamColor: teamColor,
          childBuilder: (context, teamColor, isHighlighted) => AnimatedScale(
            scale: 2 / 3,
            duration: Duration.zero,
            child: SvgPicture.asset(
              'assets/images/frc_cone.svg',
              colorFilter: ColorFilter.mode(
                isHighlighted
                    ? teamColor ?? Theme.of(context).colorScheme.primary
                    : Colors.white,
                BlendMode.srcIn,
              ),
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              height: 16,
              width: 16,
            ),
          ),
        );
      case AutoPathEventType.pickUpCube:
        return AutoPathEventIndicator(
          isHighlighted: [
            AutoPathLocation.communityCenter1,
            AutoPathLocation.communityCenter2,
            AutoPathLocation.communityCenter3,
          ].contains(location),
          teamColor: teamColor,
          childBuilder: (context, teamColor, isHighlighted) => AnimatedScale(
            scale: 2 / 3,
            duration: Duration.zero,
            child: SvgPicture.asset(
              'assets/images/frc_cube.svg',
              colorFilter: ColorFilter.mode(
                isHighlighted
                    ? teamColor ?? Theme.of(context).colorScheme.primary
                    : Colors.white,
                BlendMode.srcIn,
              ),
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              height: 16,
              width: 16,
            ),
          ),
        );
      case AutoPathEventType.placeCone:
        return AutoPathEventIndicator(
          teamColor: teamColor,
          childBuilder: (context, teamColor, isHighlighted) => AnimatedScale(
            scale: 2 / 3,
            duration: Duration.zero,
            child: SvgPicture.asset(
              'assets/images/frc_cone.svg',
              colorFilter: ColorFilter.mode(
                isHighlighted
                    ? teamColor ?? Theme.of(context).colorScheme.primary
                    : Colors.white,
                BlendMode.srcIn,
              ),
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
            ),
          ),
        );
      case AutoPathEventType.placeCube:
        return AutoPathEventIndicator(
          teamColor: teamColor,
          childBuilder: (context, teamColor, isHighlighted) => AnimatedScale(
            scale: 2 / 3,
            duration: Duration.zero,
            child: SvgPicture.asset(
              'assets/images/frc_cube.svg',
              colorFilter: ColorFilter.mode(
                isHighlighted
                    ? teamColor ?? Theme.of(context).colorScheme.primary
                    : Colors.white,
                BlendMode.srcIn,
              ),
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
            ),
          ),
        );
      case AutoPathEventType.chargeStation:
        return AutoPathEventIndicator(
          teamColor: teamColor,
          childBuilder: (context, teamColor, isHighlighted) =>
              iconAutoPathEventIndicator(
            context,
            teamColor,
            isHighlighted,
            Icons.bolt,
          ),
        );
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
  pickUpCube,
  pickUpCone,
  unknown2,
  dropItem,
  placeCube,
  placeCone,
  unknown6,
  crossCommunityBorder,
  startWithoutItem,
  chargeStation,
}

enum GamePiece {
  cube,
  cone,
}

extension GamePieceExtension on GamePiece {
  Widget icon({Color color = Colors.white}) {
    switch (this) {
      case GamePiece.cube:
        return Transform.scale(
            scale: 2 / 3,
            child: SvgPicture.asset(
              'assets/images/frc_cube.svg',
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              height: 16,
              width: 16,
            ));
      case GamePiece.cone:
        return Transform.scale(
            scale: 2 / 3,
            child: SvgPicture.asset(
              'assets/images/frc_cone.svg',
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
  });

  final Color? teamColor;
  final bool isHighlighted;
  final Widget Function(
    BuildContext context,
    Color? teamColor,
    bool isHighlighted,
  ) childBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: 24,
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
  grid1,
  grid2,
  grid3,
  grid4,
  grid5,
  grid6,
  grid7,
  grid8,
  grid9,

  /// The cable protector connected to the charge station
  cableProtector,
  chargeStation,
  communityBorderNearBarrier,

  /// Farthest from the scoring table
  prePlacedPiece1,

  /// 3rd closest to the scoring table
  prePlacedPiece2,

  /// 2nd closest to the scoring table
  prePlacedPiece3,

  /// Closest to the scoring table
  prePlacedPiece4,

  /// Center of the community ajacent to tag 3
  communityCenter3,

  /// Center of the community ajacent to tag 2
  communityCenter2,

  /// Center of the community ajacent to tag 1
  communityCenter1,
}

extension AutoPathLocationExtension on AutoPathLocation {
  /// `x` and `y` are between `0` and `100`, starting from the top right of the field.
  Offset get offset {
    switch (this) {
      case AutoPathLocation.cableProtector:
        return const Offset(51, 88);
      case AutoPathLocation.chargeStation:
        return const Offset(51, 50);
      case AutoPathLocation.communityBorderNearBarrier:
        return const Offset(58, 14);
      case AutoPathLocation.communityCenter1:
        return const Offset(75, 75);
      case AutoPathLocation.communityCenter2:
        return const Offset(75, 50);
      case AutoPathLocation.communityCenter3:
        return const Offset(75, 25);
      case AutoPathLocation.grid1:
        return const Offset(86, 82);
      case AutoPathLocation.grid2:
        return const Offset(86, 50);
      case AutoPathLocation.grid3:
        return const Offset(86, 20);
      case AutoPathLocation.grid4:
        return const Offset(91, 82);
      case AutoPathLocation.grid5:
        return const Offset(91, 50);
      case AutoPathLocation.grid6:
        return const Offset(91, 20);
      case AutoPathLocation.grid7:
        return const Offset(96, 82);
      case AutoPathLocation.grid8:
        return const Offset(96, 50);
      case AutoPathLocation.grid9:
        return const Offset(96, 20);
      case AutoPathLocation.prePlacedPiece1:
        return const Offset(10.27, 16.7);
      case AutoPathLocation.prePlacedPiece2:
        return const Offset(10.27, 39.2);
      case AutoPathLocation.prePlacedPiece3:
        return const Offset(10.27, 61.6);
      case AutoPathLocation.prePlacedPiece4:
        return const Offset(10.27, 84);
      default:
        return const Offset(0, 0);
    }
  }

  Offset get randomVariance {
    switch (this) {
      case AutoPathLocation.chargeStation:
        return const Offset(4, 9);
      case AutoPathLocation.prePlacedPiece1:
        return const Offset(0, 0);
      case AutoPathLocation.prePlacedPiece2:
        return const Offset(0, 0);
      case AutoPathLocation.prePlacedPiece3:
        return const Offset(0, 0);
      case AutoPathLocation.prePlacedPiece4:
        return const Offset(0, 0);
      case AutoPathLocation.cableProtector:
        return const Offset(0, 7);
      case AutoPathLocation.communityBorderNearBarrier:
        return const Offset(0, 5);
      case AutoPathLocation.grid1:
        return const Offset(1.3, 4);
      case AutoPathLocation.grid2:
        return const Offset(1.3, 4);
      case AutoPathLocation.grid3:
        return const Offset(1.3, 4);
      case AutoPathLocation.grid4:
        return const Offset(1.3, 4);
      case AutoPathLocation.grid5:
        return const Offset(1.3, 4);
      case AutoPathLocation.grid6:
        return const Offset(1.3, 4);
      case AutoPathLocation.grid7:
        return const Offset(1.3, 4);
      case AutoPathLocation.grid8:
        return const Offset(1.3, 4);
      case AutoPathLocation.grid9:
        return const Offset(1.3, 4);
      default:
        return const Offset(2, 2);
    }
  }
}
