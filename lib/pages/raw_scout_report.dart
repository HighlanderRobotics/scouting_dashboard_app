import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:intl/intl.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/team_per_match.dart';
import 'package:scouting_dashboard_app/reusable/color_combination.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/delete_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_events_for_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_scout_report_analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_scout_reports_by_long_match_key.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/update_note.dart';
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
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                colorCombination: ColorCombination.colored,
                label: const Text("Score"),
                value: Text(reportAnalysis.totalPoints.toString()),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: roleContainer(reportAnalysis),
            ),
          ].withSpaceBetween(width: 10),
        ),
        sectionTitle("Auto"),
        AnimatedAutoPath(analysis: reportAnalysis),
        ValueTile(
          value: Text(reportAnalysis.autoPath.scores[0].toString()),
          label: const Text("Path score"),
          colorCombination: ColorCombination.colored,
        ),
        sectionTitle("Coral scoring"),
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("L1"),
                value: Text(reportAnalysis.coralL1.toString()),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("L2"),
                value: Text(reportAnalysis.coralL2.toString()),
              ),
            ),
          ].withSpaceBetween(width: 10),
        ),
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("L3"),
                value: Text(reportAnalysis.coralL3.toString()),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("L4"),
                value: Text(reportAnalysis.coralL4.toString()),
              ),
            ),
          ].withSpaceBetween(width: 10),
        ),
        sectionTitle("Algae scoring"),
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("Net, success"),
                value: Text(reportAnalysis.netScores.toString()),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("Net, fail"),
                value: Text(reportAnalysis.netFails.toString()),
              ),
            ),
          ].withSpaceBetween(width: 10),
        ),
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("Processor"),
                value: Text(reportAnalysis.processorScores.toString()),
              ),
            ),
          ].withSpaceBetween(width: 10),
        ),
        sectionTitle("Driving"),
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: driverAbilityContainer(reportAnalysis),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("Defense"),
                value: Text(reportAnalysis.defense.toString()),
              ),
            ),
          ].withSpaceBetween(width: 10),
        ),
        sectionTitle("Endgame"),
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("Barge result"),
                value:
                    Text(reportAnalysis.bargeResult.descriptionWithoutAccuracy),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: ValueTile(
                label: const Text("Climb success"),
                value: Text(
                    reportAnalysis.bargeResult.isSuccess ? "Success" : "Fail"),
              ),
            ),
          ].withSpaceBetween(width: 10),
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

  Widget sectionTitle(String title) {
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

  Widget driverAbilityContainer(SingleScoutReportAnalysis reportAnalysis) {
    return ValueTile(
      label: const Text("Driver ability"),
      value: Text("${reportAnalysis.driverAbility.index}/5"),
    );
  }

  Widget roleContainer(SingleScoutReportAnalysis reportAnalysis) {
    return ValueTile(
      colorCombination: ColorCombination.colored,
      label: const Text(
        "Role",
      ),
      value: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            reportAnalysis.robotRole.littleEmblem,
            size: 32,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 5),
          Text(
            reportAnalysis.robotRole.name,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                      color: Theme.of(context).colorScheme.surfaceVariant,
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

enum BargeResult {
  none,
  parked,
  shallowSuccess,
  shallowFail,
  deepSuccess,
  deepFail,
}

extension BargeResultExtension on BargeResult {
  String get localizedDescription {
    switch (this) {
      case BargeResult.none:
        return "None";
      case BargeResult.parked:
        return "Parked";
      case BargeResult.shallowSuccess:
        return "Shallow, success";
      case BargeResult.shallowFail:
        return "Shallow, fail";
      case BargeResult.deepSuccess:
        return "Deep, success";
      case BargeResult.deepFail:
        return "Deep, fail";
      default:
        return "Unknown";
    }
  }

  String get descriptionWithoutAccuracy {
    switch (this) {
      case BargeResult.shallowSuccess:
      case BargeResult.shallowFail:
        return "Shallow";
      case BargeResult.deepSuccess:
      case BargeResult.deepFail:
        return "Deep";
      default:
        return localizedDescription;
    }
  }

  bool get isSuccess {
    switch (this) {
      case BargeResult.shallowFail:
      case BargeResult.deepFail:
        return false;
      default:
        return true;
    }
  }
}

enum DriverAbility {
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
      default:
        return "Unknown";
    }
  }
}

class ScoutReportEvent {
  const ScoutReportEvent({
    required this.timestamp,
    required this.action,
    required this.position,
  });

  final Duration timestamp;
  final ScoutReportEventAction action;
  final ScoutReportEventPosition position;

  factory ScoutReportEvent.fromList(List<int> list) => ScoutReportEvent(
        timestamp: Duration(seconds: list[0]),
        action: ScoutReportEventAction.values[list[1]],
        position: ScoutReportEventPosition.values[list[2]],
      );

  String get localizedDescription {
    String output = action.localizedPastTense;

    if (position != ScoutReportEventPosition.none) {
      output += " at ${position.localizedDescription}";
    }

    return output;
  }
}

enum ScoutReportEventAction {
  intakeCoral,
  intakeAlgae,
  feedAlgae,
  leave,
  defend,
  scoreNetSuccess,
  scoreNetFail,
  scoreProcessor,
  scoreCoral,
  dropAlgae,
  dropCoral,
  startingPosition,
}

extension ScoutReportEventActionExtension on ScoutReportEventAction {
  String get localizedPastTense {
    switch (this) {
      case ScoutReportEventAction.leave:
        return "Left the starting zone";
      case ScoutReportEventAction.intakeCoral:
        return "Collected a coral";
      case ScoutReportEventAction.intakeAlgae:
        return "Collected an algae";
      case ScoutReportEventAction.dropAlgae:
        return "Dropped an algae";
      case ScoutReportEventAction.dropCoral:
        return "Dropped a coral";
      case ScoutReportEventAction.scoreCoral:
        return "Scored a coral";
      case ScoutReportEventAction.scoreNetSuccess:
        return "Successfully scored an algae in the net";
      case ScoutReportEventAction.scoreNetFail:
        return "Failed to score an algae in the net";
      case ScoutReportEventAction.scoreProcessor:
        return "Scored an algae in the processor";
      case ScoutReportEventAction.defend:
        return "Made a defensive action";
      case ScoutReportEventAction.feedAlgae:
        return "Fed an algae";
      case ScoutReportEventAction.startingPosition:
        return "Started the match";
    }
  }
}

enum ScoutReportEventPosition {
  none,
  startOne,
  startTwo,
  startThree,
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
  groundPieceA,
  groundPieceB,
  groundPieceC,
  coralStationOne,
  coralStationTwo,
}

extension ScoutReportEventPositionExtension on ScoutReportEventPosition {
  String get localizedDescription {
    switch (this) {
      case ScoutReportEventPosition.none:
        return "nowhere";
      case ScoutReportEventPosition.startOne:
        return "the starting line, far left";
      case ScoutReportEventPosition.startTwo:
        return "the starting line, mid left";
      case ScoutReportEventPosition.startThree:
        return "the starting line, mid right";
      case ScoutReportEventPosition.startFour:
        return "the starting line, far right";
      case ScoutReportEventPosition.reefL1:
        return "L1 on the reef";
      case ScoutReportEventPosition.reefL2:
        return "L2 on the reef";
      case ScoutReportEventPosition.reefL3:
        return "L3 on the reef";
      case ScoutReportEventPosition.reefL4:
        return "L4 on the reef";
      case ScoutReportEventPosition.reefL1A:
        return "L1 on the reef, drivers' right";
      case ScoutReportEventPosition.reefL1B:
        return "L1 on the reef, drivers' left";
      case ScoutReportEventPosition.reefL1C:
        return "L1 on the reef, far side from drivers";
      case ScoutReportEventPosition.reefL2A:
        return "L2 on the reef, drivers' right";
      case ScoutReportEventPosition.reefL2B:
        return "L2 on the reef, drivers' left";
      case ScoutReportEventPosition.reefL2C:
        return "L2 on the reef, far side from drivers";
      case ScoutReportEventPosition.reefL3A:
        return "L3 on the reef, drivers' right";
      case ScoutReportEventPosition.reefL3B:
        return "L3 on the reef, drivers' left";
      case ScoutReportEventPosition.reefL3C:
        return "L3 on the reef, far side from drivers";
      case ScoutReportEventPosition.reefL4A:
        return "L4 on the reef, drivers' right";
      case ScoutReportEventPosition.reefL4B:
        return "L4 on the reef, drivers' left";
      case ScoutReportEventPosition.reefL4C:
        return "L4 on the reef, far side from drivers";
      case ScoutReportEventPosition.groundPieceA:
        return "the ground piece, drivers' right";
      case ScoutReportEventPosition.groundPieceB:
        return "the ground piece, drivers' left";
      case ScoutReportEventPosition.groundPieceC:
        return "the ground piece, far side from drivers";
      case ScoutReportEventPosition.coralStationOne:
        return "the coral station on the left";
      case ScoutReportEventPosition.coralStationTwo:
        return "the coral station on the right";
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
