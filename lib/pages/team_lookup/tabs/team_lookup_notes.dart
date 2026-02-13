import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_notes_analysis.dart';
import 'package:scouting_dashboard_app/pages/raw_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_notes.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:skeletons_forked/skeletons_forked.dart';

class TeamLookupNotesVizualization extends AnalysisVisualization {
  const TeamLookupNotesVizualization({
    super.key,
    required this.function,
    super.updateIncrement,
  }) : super(analysisFunction: function);

  final TeamLookupNotesAnalysis function;

  @override
  Widget loadingView() {
    return PageBody(
      bottom: false,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: SkeletonListView(
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SkeletonAvatar(
            style: SkeletonAvatarStyle(
              borderRadius: BorderRadius.circular(10),
              randomHeight: true,
              minHeight: 74,
              maxHeight: 160,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    final notes = snapshot.data as List<Note>;

    return notes.isEmpty
        ? SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 100),
                Image.asset(
                  'assets/images/no-notes-${Theme.of(context).brightness.name}.png',
                  width: 250,
                ),
                Text(
                  "No notes on ${function.team}",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          )
        : ScrollablePageBody(
            children: [
              NotesList(
                notes: (notes)
                    .map(
                      (note) => NoteWidget(
                        note,
                        onEdit: () => super.loadData(),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
  }
}

class BreakDescriptionsPage extends StatelessWidget {
  const BreakDescriptionsPage({super.key, required this.breakDescriptions});

  final List<NoteWidget> breakDescriptions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Robot Breaks"),
      ),
      body: ScrollablePageBody(
          children: [NotesList(notes: breakDescriptions, showWarning: false)]),
    );
  }
}

class RobotBrokeBox extends StatelessWidget {
  const RobotBrokeBox({super.key, required this.breakDescriptions});

  final List<NoteWidget> breakDescriptions;

  @override
  Widget build(BuildContext context) {
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

    final String description = "${breakDescriptions.length} reports";

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushWidget(
            BreakDescriptionsPage(breakDescriptions: breakDescriptions));
      },
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
}

class NotesList extends StatelessWidget {
  const NotesList({Key? key, required this.notes, this.showWarning = true})
      : super(key: key);

  final List<NoteWidget> notes;
  final bool showWarning;
  @override
  Widget build(BuildContext context) {
    final List<NoteWidget> notes =
        this.notes.where((e) => e.note.type == NoteType.note).toList();
    final List<NoteWidget> breakDescriptions = this
        .notes
        .where((e) => e.note.type == NoteType.breakDescription)
        .toList();

    return Column(
      spacing: 15,
      children: [
        ...breakDescriptions.isEmpty || !showWarning
            ? []
            : [RobotBrokeBox(breakDescriptions: breakDescriptions)],
        ...notes.isEmpty ? [] : notes,
        ...!showWarning
            ? breakDescriptions.map((e) => NoteWidget(
                  e.note,
                  foregroundColor: HSLColor.fromColor(Colors.amber)
                      .withSaturation(1)
                      .withLightness(0.8)
                      .toColor(),
                  backgroundColor: HSLColor.fromColor(Colors.amber)
                      .withSaturation(1)
                      .withLightness(0.2)
                      .toColor(),
                ))
            : [],
      ],
    );
  }
}

class NoteWidget extends StatelessWidget {
  const NoteWidget(
    this.note, {
    Key? key,
    this.foregroundColor,
    this.backgroundColor,
    this.onEdit,
  }) : super(key: key);

  final Note note;
  final dynamic Function()? onEdit;

  final Color? backgroundColor;
  final Color? foregroundColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color:
            backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    note.type == NoteType.breakDescription
                        ? "Robot broke in ${note.matchIdentity.getLocalizedDescription(abbreviateName: true)}"
                        : note.matchIdentity.getLocalizedDescription(),
                    style: Theme.of(context).textTheme.titleMedium!.merge(
                          TextStyle(
                            color: foregroundColor ??
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                          ),
                        ),
                  ),
                ),
                if (note.uuid != null) ...[
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushWidget(
                        NotesEditor(
                          uuid: note.uuid!,
                          initialNotes: note.body,
                          onSubmitted: () => onEdit?.call(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.edit_outlined,
                      color: foregroundColor ??
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            Text(
              note.body,
              style: Theme.of(context).textTheme.bodyMedium!.merge(
                    TextStyle(
                      color: foregroundColor ??
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
            ),
            if (note.author != null) ...[
              const SizedBox(height: 4),
              Text(
                note.author!,
                style: Theme.of(context).textTheme.bodyMedium!.merge(
                      TextStyle(
                        color: foregroundColor?.withValues(alpha: 0.85) ??
                            Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.7),
                      ),
                    ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
