import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/pages/team_per_match.dart';
import 'package:scouting_dashboard_app/reusable/color_combination.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/delete_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_events_for_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_scout_report_analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_scout_reports_by_long_match_key.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/update_note.dart';
import 'package:scouting_dashboard_app/reusable/models/match.dart';
import 'package:scouting_dashboard_app/reusable/models/robot_roles.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';
import 'package:scouting_dashboard_app/reusable/value_tile.dart';

class RawScoutReportsPage extends StatefulWidget {
  const RawScoutReportsPage({
    super.key,
    required this.longMatchKey,
    required this.teamNumber,
  });

  final String longMatchKey;
  final int teamNumber;

  GameMatchIdentity get matchIdentity =>
      GameMatchIdentity.fromLongKey(longMatchKey);

  @override
  State<RawScoutReportsPage> createState() => _RawScoutReportsPageState();
}

class _RawScoutReportsPageState extends State<RawScoutReportsPage> {
  List<MinimalScoutReportInfo>? reports;
  String? error;

  Future<void> fetchData() async {
    try {
      setState(() {
        error = null;
        this.reports = null;
      });

      final reports =
          await lovatAPI.getScoutReportsByLongMatchKey(widget.longMatchKey);

      setState(() {
        this.reports = reports;
      });
    } on LovatAPIException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (e) {
      debugPrint("$e");
      setState(() {
        error = "Failed to get reports";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = FriendlyErrorView(
      errorMessage: error,
      onRetry: () => fetchData(),
    );

    if (reports == null) {
      body = const PageBody(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      body = FriendlyErrorView(
        errorMessage: error,
        onRetry: () => fetchData(),
      );
    }

    if (reports != null) {
      body = ListView(
        children: reports!
            .map((report) => ListTile(
                  title: Text(report.scout.name),
                  // In format "Today at 12:34 PM" or "Yesterday at 12:34 PM" or "Monday at 12:34 PM" or "12/31/2021 at 12:34 PM"
                  subtitle: Text(localizeTimestamp(report.timestamp)),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/raw_scout_report',
                      arguments: {
                        'uuid': report.uuid,
                        'teamNumber': widget.teamNumber,
                        'matchIdentity': widget.matchIdentity,
                        'scoutName': report.scout.name,
                        'onDeleted': () {
                          fetchData();
                        },
                      },
                    );
                  },
                  trailing: const Icon(Icons.chevron_right),
                ))
            .toList(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Data in ${widget.matchIdentity.getShortLocalizedDescription()} for ${widget.teamNumber}",
        ),
      ),
      body: body,
    );
  }

  String localizeTimestamp(DateTime timestamp) {
    // In format "Today at 12:34 PM" or "Yesterday at 12:34 PM" or "Monday at 12:34 PM" or "12/31/2021 at 12:34 PM"
    final now = DateTime.now();
    final dateTime = timestamp.toLocal();

    final time = TimeOfDay.fromDateTime(dateTime).format(context);

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return "Today at $time";
    }

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day - 1) {
      return "Yesterday at $time";
    }

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day - now.day < 7) {
      final formatter = DateFormat('EEEE');

      return "${formatter.format(dateTime)} at $time";
    }

    final formatter = DateFormat('MM/dd/yyyy');

    return "${formatter.format(dateTime)} at $time";
  }
}

class RawScoutReportPage extends StatefulWidget {
  const RawScoutReportPage({
    super.key,
    required this.uuid,
    required this.teamNumber,
    required this.matchIdentity,
    required this.scoutName,
    this.onDeleted,
  });

  final String uuid;
  final int teamNumber;
  final GameMatchIdentity matchIdentity;
  final String scoutName;

  final dynamic Function()? onDeleted;

  @override
  State<RawScoutReportPage> createState() => _RawScoutReportPageState();
}

class _RawScoutReportPageState extends State<RawScoutReportPage> {
  SingleScoutReportAnalysis? reportAnalysis;
  List<ScoutReportEvent>? timeline;
  bool loading = false;

  String? error;

  Future<void> fetchData() async {
    try {
      setState(() {
        error = null;
        loading = true;
      });

      final reportAnalysis = await lovatAPI.getScoutReportAnalysis(widget.uuid);
      final timeline = await lovatAPI.getEventsForScoutReport(widget.uuid);

      setState(() {
        this.reportAnalysis = reportAnalysis;
        this.timeline = timeline;
      });
    } on LovatAPIException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (e) {
      debugPrint("$e");
      setState(() {
        error = "Failed to get report";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: FriendlyErrorView(
          errorMessage: error,
          onRetry: () => fetchData(),
        ),
      );
    }

    final appBarTitle = Text(
        "${widget.teamNumber} in ${widget.matchIdentity.getShortLocalizedDescription()} - ${widget.scoutName}");

    if (reportAnalysis == null) {
      return Scaffold(
        appBar: AppBar(
          title: appBarTitle,
        ),
        body: const PageBody(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: appBarTitle,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(loading ? 53 : 49),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TabBar(tabs: [
                  Tab(text: "Overview"),
                  Tab(text: "Timeline"),
                ]),
                if (loading) const LinearProgressIndicator(),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Delete report",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DeleteReportDialog(
                    uuid: widget.uuid,
                    onDeleted: () {
                      widget.onDeleted?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                  barrierDismissible: false,
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            overviewTab(reportAnalysis!),
            timelineTab(timeline!, context),
          ],
        ),
      ),
    );
  }

  Widget overviewTab(SingleScoutReportAnalysis reportAnalysis) {
    return ScrollablePageBody(
      children: [
        if (reportAnalysis.robotBrokeDescription != null)
          robotBrokeBox(reportAnalysis.robotBrokeDescription!),
        const SectionTitle("Score"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8.0,
          children: [
            Expanded(
                child: ValueTile(
                    value: Text("${reportAnalysis.totalPoints}"),
                    label: const Text("Total"))),
            Expanded(
                child: ValueTile(
                    value: Text(
                        "${reportAnalysis.totalPoints - reportAnalysis.autoScore}"),
                    label: const Text("Teleop"))),
            Expanded(
                child: ValueTile(
                    value: Text("${reportAnalysis.autoScore}"),
                    label: const Text("Auto")))
          ],
        ),
        const SectionTitle("Roles"),
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: reportAnalysis.robotRoles.map((role) {
                return SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  height: 60,
                  child: roleContainer(role),
                );
              }).toList(),
            );
          },
        ),
        const SectionTitle("Shooting"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8.0,
          children: [
            Expanded(
                child: ValueTile(
                    value: Text((() {
                      switch (reportAnalysis.climbResult) {
                        case EndgameClimbResult.l1:
                          return "${reportAnalysis.totalPoints - 10}";
                        case EndgameClimbResult.l2:
                          return "${reportAnalysis.totalPoints - 20}";
                        case EndgameClimbResult.l3:
                          return "${reportAnalysis.totalPoints - 30}";
                        default:
                          return "${reportAnalysis.totalPoints}";
                      }
                    })()),
                    label: const Text("Fuel Scored"))),
            Expanded(
                child: ValueTile(
                    value: Text((() {
                      switch (reportAnalysis.accuracy) {
                        case 0:
                          return "<50";
                        case 1:
                          return "50-60";
                        case 2:
                          return "60-70";
                        case 3:
                          return "70-80";
                        case 4:
                          return "80-90";
                        case 5:
                          return "90-100";
                        default:
                          return "-";
                      }
                    })()),
                    label: const Text("% Accuracy"))),
            Expanded(
                child: ValueTile(
                    value: Text("${reportAnalysis.scoringRate}"),
                    label: const Text("BPS")))
          ],
        ),
        const SectionTitle("Auto"),
        AnimatedAutoPath(analysis: reportAnalysis),
        ValueTile(
          value: Text("${reportAnalysis.autoScore}"),
          label: const Text("Path score"),
          colorCombination: ColorCombination.colored,
        ),
        const SectionTitle("Driving & Defense"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8.0,
          children: [
            Expanded(
                child: ValueTile(
                    value: Text("${reportAnalysis.campingDefenseTime}s"),
                    label: const Text("Camping Defense"))),
            Expanded(
                child: ValueTile(
                    value: Text("${reportAnalysis.contactDefenseTime}s"),
                    label: const Text("Contact Defense")))
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              flex: 2,
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("Defense Effectiveness"),
                value: Text("${reportAnalysis.defenseEffectiveness}/5"),
              ),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: ValueTile(
                  value: Text("${reportAnalysis.driverAbility}/5"),
                  label: const Text("Driver Ability")),
            ),
          ].withSpaceBetween(width: 10),
        ),
        const SectionTitle("Feeding"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8.0,
          children: [
            Expanded(
                child: ValueTile(
                    value:
                        Text(numToStringRounded(reportAnalysis.ballsPerFeed)),
                    label: const Text("Balls/Feed"))),
            Expanded(
                child: ValueTile(
                    value: Text("${reportAnalysis.ballsFed}"),
                    label: const Text("Balls Fed"))),
            Expanded(
                child: ValueTile(
                    value: Text("${reportAnalysis.feedingRate}"),
                    label: const Text("BPS")))
          ],
        ),
        if (reportAnalysis.robotRoles.contains(RobotRoles.feeding)) ...[
          const SectionTitle("Feeder Types"),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: reportAnalysis.feederType.map((type) {
                  return SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    height: 60,
                    child: EmphasizedContainer(
                      child: Center(
                        child: Text(
                          type.description,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          )
        ],
        const SectionTitle("Endgame"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8.0,
          children: [
            Expanded(
                child: ValueTile(
                    value: Text(
                        "${reportAnalysis.climbResult.localizedDescription} "),
                    label: const Text("Climb Result"))),
            Expanded(
                child: ValueTile(
                    value: Text("${reportAnalysis.climbStartTime}s"),
                    label: const Text("time left")))
          ],
        ),
        if (reportAnalysis.notes != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Notes",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).pushWidget(NotesEditor(
                        initialNotes: reportAnalysis.notes,
                        uuid: widget.uuid,
                        onSubmitted: () => fetchData(),
                      ));
                    },
                  ),
                ],
              ),
              Text(reportAnalysis.notes!),
            ],
          ),
      ].withSpaceBetween(height: 10),
    );
  }

  Widget robotBrokeBox(String description) {
    final backgroundColor = HSLColor.fromColor(Colors.amber)
        .withSaturation(1)
        .withLightness(0.2)
        .toColor();

    final foregroundColor = HSLColor.fromColor(Colors.amber)
        .withSaturation(1)
        .withLightness(0.8)
        .toColor();

    const double iconSize = 24;
    const double horizontalSpacing = 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: EmphasizedContainer(
        color: backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(
                Icons.warning_rounded,
                color: foregroundColor,
                size: iconSize,
              ),
              const SizedBox(width: horizontalSpacing),
              Text(
                "Robot broke",
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: foregroundColor, fontWeight: FontWeight.w600),
              )
            ]),
            if (description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: iconSize + horizontalSpacing,
                ),
                child: Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: foregroundColor.withAlpha(225)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget roleContainer(RobotRoles role) {
    return EmphasizedContainer(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            role.littleEmblem,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            role.name,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  // The tabs are actually "Overview" and "Timeline"

  SafeArea rawTab(AsyncSnapshot<Map<String, dynamic>> snapshot) {
    return SafeArea(
      child: SyntaxView(
        code: const JsonEncoder.withIndent('    ').convert(<String, dynamic>{
          ...snapshot.data!,
          'scoutReport': jsonDecode(snapshot.data!['scoutReport']),
        }),
        syntax: Syntax.JAVASCRIPT,
        syntaxTheme: SyntaxTheme.vscodeDark(),
        expanded: true,
      ),
    );
  }

  ScrollablePageBody timelineTab(
      List<ScoutReportEvent> timeline, BuildContext context) {
    return ScrollablePageBody(
      padding: const EdgeInsets.all(0),
      children: timeline
          .map((event) => Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 24,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        minutesAndSeconds(event.timestamp),
                        textAlign: TextAlign.end,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .merge(TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            )),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        event.localizedDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ].withSpaceBetween(width: 5),
                ),
              ))
          .toList(),
    );
  }

  Widget field(String title, String value, {Widget? valueLeading}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Row(
            children: [
              if (valueLeading != null) valueLeading,
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ].withSpaceBetween(width: 2),
          ),
        ],
      );
}

enum EndgameClimbResult {
  notAttempted,
  failed,
  l1,
  l2,
  l3,
}

extension EndgameClimbResultExtension on EndgameClimbResult {
  String get localizedDescription {
    switch (this) {
      case EndgameClimbResult.notAttempted:
        return "None";
      case EndgameClimbResult.failed:
        return "Failed";
      case EndgameClimbResult.l1:
        return "L2";
      case EndgameClimbResult.l2:
        return "L2";
      case EndgameClimbResult.l3:
        return "L3";
    }
  }
}

enum FeederType {
  continuous,
  stopToShoot,
  dump,
}

extension FeederTypeName on FeederType {
  String get description {
    switch (this) {
      case FeederType.continuous:
        return "Continuous";
      case FeederType.dump:
        return "Dump";
      case FeederType.stopToShoot:
        return "Stop to Shoot";
    }
  }
}

enum AutoClimbResult {
  notAttempted,
  failed,
  succeeded,
}

enum DriverAbility {
  terrible,
  poor,
  average,
  good,
  great,
}

enum DefenseEffectiveness {
  terrible,
  poor,
  average,
  good,
  great,
}

extension DriverAbilityExtension on DriverAbility {
  String get localizedDescription {
    switch (this) {
      case DriverAbility.terrible:
        return "Terrible";
      case DriverAbility.poor:
        return "Poor";
      case DriverAbility.average:
        return "Average";
      case DriverAbility.good:
        return "Good";
      case DriverAbility.great:
        return "Great";
    }
  }
}

class ScoutReportEvent {
  const ScoutReportEvent(
      {required this.timestamp,
      required this.action,
      required this.position,
      this.quantity});

  final Duration timestamp;
  final ScoutReportEventAction action;
  final ScoutReportEventPosition position;
  final num? quantity;

  factory ScoutReportEvent.fromList(List<int> list) => ScoutReportEvent(
      timestamp: Duration(seconds: list[0]),
      action: ScoutReportEventAction.values[list[1]],
      position: ScoutReportEventPosition.values[list[2]],
      quantity: list.length >= 4 ? list[3] : 0);

  String get localizedDescription {
    String output = action.localizedPastTense;

    if (quantity != null && quantity! > 0) {
      output += " $quantity fuel";
    }

    if (position != ScoutReportEventPosition.none) {
      output += " at ${position.localizedDescription}";
    }

    return output;
  }
}

enum Accuracy {
  underFifty,
  fifty,
  sixty,
  seventy,
  eighty,
  ninetyPlus,
}

enum ScoutReportEventAction {
  startScoring,
  stopScoring,
  startMatch,
  startCamping,
  stopCamping,
  startDefending,
  stopDefending,
  intake,
  outtake,
  disrupt,
  cross,
  climb,
  startFeeding,
  stopFeeding
}

extension ScoutReportEventActionExtension on ScoutReportEventAction {
  String get localizedPastTense {
    switch (this) {
      case ScoutReportEventAction.startScoring:
        return "Started scoring";
      case ScoutReportEventAction.stopScoring:
        return "Finished scoring";
      case ScoutReportEventAction.startMatch:
        return "Started the match";
      case ScoutReportEventAction.startCamping:
        return "Started camping";
      case ScoutReportEventAction.stopCamping:
        return "Stopped camping";
      case ScoutReportEventAction.startDefending:
        return "Started contact defending";
      case ScoutReportEventAction.stopDefending:
        return "Stopped contact defending";
      case ScoutReportEventAction.intake:
        return "Took in fuel";
      case ScoutReportEventAction.outtake:
        return "Outtaked fuel";
      case ScoutReportEventAction.disrupt:
        return "Disrupt neutral zone fuel";
      case ScoutReportEventAction.cross:
        return "Crossed into the neutral zone";
      case ScoutReportEventAction.climb:
        return "Started climbing";
      case ScoutReportEventAction.startFeeding:
        return "Started feeding";
      case ScoutReportEventAction.stopFeeding:
        return "Finished feeding";
    }
  }
}

enum ScoutReportEventPosition {
  leftTrench,
  leftBump,
  hub,
  rightTrench,
  rightBump,
  neutralZone,
  depot,
  outpost,
  none,
}

extension ScoutReportEventPositionExtension on ScoutReportEventPosition {
  String get localizedDescription {
    switch (this) {
      case ScoutReportEventPosition.leftTrench:
        return "the left trench";
      case ScoutReportEventPosition.leftBump:
        return "the left bump";
      case ScoutReportEventPosition.hub:
        return "the hub";
      case ScoutReportEventPosition.rightTrench:
        return "the right trench";
      case ScoutReportEventPosition.rightBump:
        return "the right bump";
      case ScoutReportEventPosition.neutralZone:
        return "the neutral zone";
      case ScoutReportEventPosition.depot:
        return "the depot";
      case ScoutReportEventPosition.outpost:
        return "the outpost";
      case ScoutReportEventPosition.none:
        return "";
    }
  }
}

class NotesEditor extends StatefulWidget {
  const NotesEditor({
    super.key,
    this.initialNotes,
    this.onSubmitted,
    required this.uuid,
  });

  final String? initialNotes;
  final String uuid;
  final dynamic Function()? onSubmitted;

  @override
  State<NotesEditor> createState() => _NotesEditorState();
}

class _NotesEditorState extends State<NotesEditor> {
  final TextEditingController notesController = TextEditingController();

  String notes = "";
  bool submitLoading = false;
  String? error;

  @override
  void dispose() {
    super.dispose();
    notesController.dispose();
  }

  @override
  void initState() {
    super.initState();
    notes = widget.initialNotes ?? "";
    notesController.text = notes;
  }

  Future<void> submit() async {
    final navigation = Navigator.of(context);
    setState(() {
      submitLoading = true;
      error = null;
    });

    try {
      await lovatAPI.updateNote(widget.uuid, notes);
      if (navigation.canPop()) {
        navigation.pop();
      }
      widget.onSubmitted?.call();
    } on LovatAPIException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (e) {
      setState(() {
        error = "Failed to update notes";
      });
    } finally {
      setState(() {
        submitLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Edit Notes"),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: submit,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: submitLoading
                ? const LinearProgressIndicator()
                : const SizedBox(height: 4),
          )),
      body: PageBody(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TextField(
          controller: notesController,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(border: InputBorder.none),
          textAlignVertical: TextAlignVertical.top,
          autofocus: true,
          onChanged: (value) {
            setState(() {
              notes = value;
            });
          },
        ),
      ),
    );
  }
}

class DeleteReportDialog extends StatefulWidget {
  const DeleteReportDialog({
    super.key,
    required this.uuid,
    this.onDeleted,
  });

  final String uuid;
  final dynamic Function()? onDeleted;

  @override
  State<DeleteReportDialog> createState() => _DeleteReportDialogState();
}

class _DeleteReportDialogState extends State<DeleteReportDialog> {
  bool deleting = false;
  String? error;

  Future<void> delete() async {
    final navigation = Navigator.of(context);
    setState(() {
      deleting = true;
      error = null;
    });

    try {
      await lovatAPI.deleteScoutReport(widget.uuid);
      if (navigation.canPop()) {
        navigation.pop();
      }
      widget.onDeleted?.call();
    } on LovatAPIException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (e) {
      setState(() {
        error = "Failed to delete report";
      });
    } finally {
      setState(() {
        deleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete report"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Are you sure you want to delete this report?",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                error!,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: delete,
          child: deleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const Text("Delete"),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
            ),
      ),
    );
  }
}
