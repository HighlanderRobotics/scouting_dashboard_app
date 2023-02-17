import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_notes_analysis.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class TeamLookupNotesVizualization extends AnalysisVisualization {
  const TeamLookupNotesVizualization({
    super.key,
    required this.function,
  }) : super(analysisFunction: function);

  final TeamLookupNotesAnalysis function;

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    return ScrollablePageBody(
      children: [
        if ((snapshot.data as List).isEmpty) const Text("No notes"),
        if ((snapshot.data as List).isNotEmpty)
          NotesList(
            notes: ((snapshot.data as List).cast<Map<String, dynamic>>())
                .where((note) => note['notes'] != null && note['notes'] != "")
                .map((note) => Note(
                    matchName: GameMatchIdentity.fromLongKey(note['matchKey'])
                        .getLocalizedDescription(includeTournament: false),
                    noteBody: note['notes']))
                .toList()
                .cast<Note>(),
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

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: notes.isEmpty
          ? []
          : notes
              .expand((element) => [element, const SizedBox(height: 20)])
              .take(notes.length * 2 - 1)
              .toList(),
    );
  }
}

class Note extends StatelessWidget {
  const Note({
    Key? key,
    required this.matchName,
    required this.noteBody,
  }) : super(key: key);

  final String matchName;
  final String noteBody;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              matchName,
              style: Theme.of(context).textTheme.titleMedium!.merge(
                    TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
            ),
            Text(
              noteBody,
              style: Theme.of(context).textTheme.bodyMedium!.merge(
                    TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
