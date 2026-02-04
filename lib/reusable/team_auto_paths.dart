import 'dart:math';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup_details.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';
import 'package:scouting_dashboard_app/reusable/models/match.dart';

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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.fromLTRB(7, 4, 7, 4),
                      radius: 7,
                      child: Text(
                        "Score: ${numToStringRounded(selectedPath!.scores[selectedPath!.matches.indexOf(e)])}",
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
            numToStringRounded(selectedPath!.scores.cast<num>().average()),
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
                    "Score: ${numToStringRounded(item.scores.cast<num>().average())}",
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
      aspectRatio: 489 / 491,
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
              )),
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
  AutoPath({
    required this.frequency,
    required this.scores,
    required this.timeline,
    required this.matches,
  }) {
    trajectories = timeline.any((e) => e.type == AutoPathEventType.stopScoring)
        ? timeline
            .where((e) => e.type == AutoPathEventType.stopScoring)
            .map(
              (e) {
                List<BallTrajectory> list = [];
                AutoPathEvent startEvent = timeline.lastWhere((event) =>
                    event.type == AutoPathEventType.startScoring &&
                    event.timestamp < e.timestamp);
                if (e.quantity != null && e.quantity! > 0) {
                  for (int i = 1; i <= e.quantity!; i++) {
                    Duration startTime = Duration(
                        microseconds: (startEvent.timestamp.inMicroseconds +
                                i /
                                    e.quantity! *
                                    (e.timestamp.inMicroseconds -
                                        startEvent.timestamp.inMicroseconds))
                            .round());
                    list.add(BallTrajectory(
                        endPos: AutoPathLocation.hub.offset,
                        startPos: Offset(positionAtTimestamp(startTime).dx,
                            positionAtTimestamp(startTime).dy),
                        startTime: startTime));
                  }
                  return list;
                } else {
                  return <BallTrajectory>[];
                }
              },
            )
            .expand((i) => i)
            .toList()
        : [];
  }

  final int frequency;
  final List<int> scores;
  final List<AutoPathEvent> timeline;
  final List<GameMatchIdentity> matches;
  late final List<BallTrajectory?> trajectories;

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
    AutoPathEvent? startEvent =
        timeline.any((event) => event.type == AutoPathEventType.startMatch)
            ? timeline
                .where((event) => event.type == AutoPathEventType.startMatch)
                .toList()[0]
            : null;

    String start = startEvent?.location.name.hyphenated ?? "Unknown";
    bool disrupts = timeline
        .where((event) => event.type == AutoPathEventType.disrupt)
        .isNotEmpty;
    num fuelScored = 0;
    timeline
        .where((e) => e.type == AutoPathEventType.stopScoring)
        .forEach((a) => fuelScored += a.quantity ?? 0);

    num fuelFed = 0;
    timeline
        .where((e) => e.type == AutoPathEventType.stopFeeding)
        .forEach((a) => fuelFed += a.quantity ?? 0);

    bool climb = timeline.any((event) => event.type == AutoPathEventType.climb);
    return "$start${fuelScored > 0 ? " $fuelScored fuel" : ""}${disrupts ? ", disrupt" : ""}${fuelFed > 0 ? ", $fuelFed feed" : ""} ${climb ? "+ climb" : ""}";
  }

  List<Offset> get offsets => timeline.map((e) => e.offset).toList();

  List<Offset> get randomizedOffsets {
    Random random = Random(timeline.hashCode);

    List<Offset> baseOffsets = timeline
        .where((e) => e.location != AutoPathLocation.none)
        .toList()
        .map((event) => Offset(
            event.offset.dx +
                (((random.nextDouble() * 2) - 0.5) * event.randomVariance.dx),
            event.offset.dy +
                (((random.nextDouble() * 2) - 0.5) * event.randomVariance.dy)))
        .toList();

    List<Offset> offsets = [];
    for (var i = 0; i < timeline.length; i++) {
      final event = timeline[i];
      offsets.add(positionAtTimestamp(event.timestamp, offsets: baseOffsets));
    }

    return offsets;
  }

  AutoPathEvent previousEventAtTimestamp(Duration timestamp,
      {List<AutoPathEvent>? filteredTimeline}) {
    late final AutoPathEvent previousEvent;
    final betterTimeline = filteredTimeline ?? timeline;
    final progress = timestamp > betterTimeline.last.timestamp
        ? betterTimeline.last.timestamp
        : timestamp;

    try {
      previousEvent = betterTimeline[
          betterTimeline.indexWhere((event) => event.timestamp >= progress) -
              1];
    } catch (e) {
      previousEvent = betterTimeline[0];
    }

    return previousEvent;
  }

  AutoPathEvent nextEventAtTimestamp(Duration timestamp,
      {List<AutoPathEvent>? filteredTimeline}) {
    final betterTimeline = filteredTimeline ?? timeline;
    final progress = timestamp > betterTimeline.last.timestamp
        ? betterTimeline.last.timestamp
        : timestamp;

    final nextEvent = betterTimeline.firstWhere(
      (event) => event.timestamp >= progress,
      orElse: () => betterTimeline.last,
    );

    return nextEvent;
  }

  Offset positionAtTimestamp(Duration timestamp, {List<Offset>? offsets}) {
    final ourOffsets = offsets ?? randomizedOffsets;
    final filteredTimeline =
        timeline.where((e) => e.location != AutoPathLocation.none).toList();
    final previousEvent =
        previousEventAtTimestamp(timestamp, filteredTimeline: filteredTimeline);

    final progress = timestamp > filteredTimeline.last.timestamp
        ? filteredTimeline.last.timestamp
        : timestamp;

    final nextEvent =
        nextEventAtTimestamp(timestamp, filteredTimeline: filteredTimeline);

    final previousOffset = ourOffsets[filteredTimeline.indexOf(previousEvent)];
    final nextOffset = ourOffsets[filteredTimeline.indexOf(nextEvent)];

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
    return [];
  }

  List<PositionedGamePiece> gamePiecePositionsAtTimestamp(Duration timestamp) {
    if (trajectories.isNotEmpty) {
      return trajectories
          .where(
        (t) => t != null && t.startTime <= timestamp && timestamp <= t.endTime,
      )
          .map((t) {
        double progress = ((timestamp - t!.startTime).inMilliseconds /
            (t.endTime - t.startTime).inMilliseconds);

        Offset position = Offset(
            progress * (t.endPos.dx - t.startPos.dx) + t.startPos.dx,
            progress * (t.endPos.dy - t.startPos.dy) + t.startPos.dy);
        return PositionedGamePiece(GamePiece.fuel, position);
      }).toList();
    } else {
      return [];
    }
  }
}

class BallTrajectory {
  const BallTrajectory({
    required this.endPos,
    required this.startPos,
    required this.startTime,
  });

  final Offset startPos;
  final Offset endPos;
  final Duration startTime;

  Duration get endTime => startTime + const Duration(milliseconds: 400);
}

class PositionedGamePiece {
  const PositionedGamePiece(this.gamePiece, this.position);

  final GamePiece gamePiece;
  final Offset position;
}

class AutoPathEvent {
  const AutoPathEvent(
      {required this.timestamp,
      required this.type,
      required this.location,
      this.quantity});

  final Duration timestamp;
  final AutoPathEventType type;
  final AutoPathLocation location;
  final num? quantity;

  /// `x` and `y` are between `0` and `100`, starting from the top right of the field.
  Offset get offset => location.offset;
  Offset get randomVariance => location.randomVariance;

  factory AutoPathEvent.fromMap(Map<String, dynamic> map) {
    AutoPathLocation loc;
    if (AutoPathEventType.values[map['event']] == AutoPathEventType.climb) {
      loc = AutoPathLocation.tower;
    } else if (AutoPathEventType.values[map['event']] ==
            AutoPathEventType.startScoring ||
        AutoPathEventType.values[map['event']] ==
            AutoPathEventType.stopScoring) {
      loc = AutoPathLocation.none;
    } else if (AutoPathEventType.values[map['event']] ==
        AutoPathEventType.startMatch) {
      loc = AutoPathLocation.values[map['location']].adjacentStartingLocation;
    } else {
      loc = AutoPathLocation.values[map['location']];
    }

    return AutoPathEvent(
      timestamp: Duration(milliseconds: map['time'] * 1000),
      type: AutoPathEventType.values[map['event']],
      location: loc,
      quantity: map['quantity'],
    );
  }

  Widget indicator(Color? teamColor) {
    switch (type) {
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
            inactiveColor: Theme.of(context).colorScheme.surface,
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
  startScoring,
  stopScoring,
  startMatch,
  unused1,
  unused2,
  unused3,
  unused4,
  intake,
  outtake,
  disrupt,
  cross,
  climb,
  startFeeding,
  stopFeeding
}

enum GamePiece { fuel }

extension GamePieceExtension on GamePiece {
  Widget icon(
      {Color color = const Color.from(alpha: 1, red: 1, green: 1, blue: 1)}) {
    return Transform.scale(
        scale: 2 / 3,
        child: SvgPicture.asset(
          'assets/images/frc_fuel.svg',
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
  leftTrench,
  leftBump,
  hub,
  rightTrench,
  rightBump,
  neutralZone,
  depot,
  outpost,
  none,
  tower,
  startLeftTrench,
  startLeftBump,
  startHub,
  startRightTrench,
  startRightBump
}

extension AutoPathLocationExtension on AutoPathLocation {
  /// `x` and `y` are between `0` and `100`, starting from the top left of the field.
  Offset get offset {
    switch (this) {
      case AutoPathLocation.leftTrench:
        return const Offset(35, 10);
      case AutoPathLocation.leftBump:
        return const Offset(35, 25);
      case AutoPathLocation.hub:
        return const Offset(42, 50);
      case AutoPathLocation.rightTrench:
        return const Offset(35, 90);
      case AutoPathLocation.rightBump:
        return const Offset(35, 75);
      case AutoPathLocation.startLeftTrench:
        return const Offset(45, 10);
      case AutoPathLocation.startLeftBump:
        return const Offset(45, 25);
      case AutoPathLocation.startHub:
        return const Offset(57.5, 50);
      case AutoPathLocation.startRightTrench:
        return const Offset(45, 90);
      case AutoPathLocation.startRightBump:
        return const Offset(45, 75);
      case AutoPathLocation.neutralZone:
        return const Offset(30, 50);
      case AutoPathLocation.depot:
        return const Offset(93, 72.5);
      case AutoPathLocation.outpost:
        return const Offset(93, 10);
      case AutoPathLocation.tower:
        return const Offset(92, 45);
      default:
        return const Offset(0, 0);
    }
  }

  AutoPathLocation get adjacentStartingLocation {
    switch (this) {
      case AutoPathLocation.leftTrench:
        return AutoPathLocation.startLeftTrench;
      case AutoPathLocation.leftBump:
        return AutoPathLocation.startLeftBump;
      case AutoPathLocation.hub:
        return AutoPathLocation.startHub;
      case AutoPathLocation.rightTrench:
        return AutoPathLocation.startRightTrench;
      case AutoPathLocation.rightBump:
        return AutoPathLocation.startRightBump;
      default:
        return AutoPathLocation.none;
    }
  }

  Offset get randomVariance {
    switch (this) {
      case AutoPathLocation.leftTrench:
      case AutoPathLocation.leftBump:
      case AutoPathLocation.hub:
      case AutoPathLocation.rightTrench:
      case AutoPathLocation.rightBump:
      case AutoPathLocation.startLeftTrench:
      case AutoPathLocation.startLeftBump:
      case AutoPathLocation.startHub:
      case AutoPathLocation.startRightBump:
      case AutoPathLocation.startRightTrench:
        return const Offset(0, 0);
      case AutoPathLocation.outpost:
      case AutoPathLocation.depot:
      case AutoPathLocation.tower:
        return const Offset(0, 5);
      default:
        return const Offset(10, 10);
    }
  }

  String get name {
    switch (this) {
      case AutoPathLocation.leftTrench:
        return "Left trench";
      case AutoPathLocation.leftBump:
        return "Left bump";
      case AutoPathLocation.hub:
        return "Hub";
      case AutoPathLocation.rightTrench:
        return "Right trench";
      case AutoPathLocation.rightBump:
        return "Right bump";
      case AutoPathLocation.neutralZone:
        return "Neutral Zone";
      case AutoPathLocation.depot:
        return "Depot";
      case AutoPathLocation.outpost:
        return "Outpost";
      case AutoPathLocation.tower:
        return "Tower";
      default:
        return "Unknown";
    }
  }
}
