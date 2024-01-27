import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_notes_analysis.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:skeletons/skeletons.dart';

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
                notes: (notes).map((note) => NoteWidget(note)).toList(),
              ),
            ],
          );
  }
}

class NotesList extends StatelessWidget {
  const NotesList({
    Key? key,
    required this.notes,
  }) : super(key: key);

  final List<NoteWidget> notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: notes.isEmpty ? [] : notes.withSpaceBetween(height: 20),
    );
  }
}

class NoteWidget extends StatelessWidget {
  const NoteWidget(
    this.note, {
    Key? key,
  }) : super(key: key);

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.matchIdentity.getLocalizedDescription(),
                  style: Theme.of(context).textTheme.titleMedium!.merge(
                        TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                ),
              ],
            ),
            Text(
              note.body,
              style: Theme.of(context).textTheme.bodyMedium!.merge(
                    TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
            ),
            if (note.author != null) ...[
              const SizedBox(height: 4),
              Text(
                note.author!,
                style: Theme.of(context).textTheme.bodyMedium!.merge(
                      TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.7),
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
