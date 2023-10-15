import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_notes_analysis.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/role_exclusive.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:http/http.dart' as http;
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
    return (snapshot.data as List).isEmpty
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
                notes: ((snapshot.data as List).cast<Map<String, dynamic>>())
                    .where(
                        (note) => note['notes'] != null && note['notes'] != "")
                    .map((note) => Note(
                          matchName:
                              GameMatchIdentity.fromLongKey(note['matchKey'])
                                  .getLocalizedDescription(
                                      includeTournament: false),
                          noteBody: note['notes'],
                          uuid: note['uuid'],
                        ))
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
    required this.uuid,
  }) : super(key: key);

  final String matchName;
  final String noteBody;
  final String uuid;

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
                  matchName,
                  style: Theme.of(context).textTheme.titleMedium!.merge(
                        TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                ),
                const Spacer(),
                RoleExclusive(
                  roles: const ["8033_scouting_lead"],
                  child: IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => EditNoteDialog(
                          initialText: noteBody,
                          uuid: uuid,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: "Edit note",
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            Text(
              noteBody,
              style: Theme.of(context).textTheme.bodyMedium!.merge(
                    TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditNoteDialog extends StatefulWidget {
  const EditNoteDialog({
    super.key,
    required this.initialText,
    required this.uuid,
  });

  final String initialText;
  final String uuid;

  @override
  State<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late final TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();

    textEditingController = TextEditingController(text: widget.initialText);
  }

  Future<void> save() async {
    final authority = (await getServerAuthority())!;

    final response =
        await http.get(Uri.http(authority, '/API/manager/editNotes', {
      'newNote': textEditingController.value.text,
      'uuid': widget.uuid,
    }));

    if (response.statusCode != 200) {
      throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit note"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: textEditingController,
            decoration: const InputDecoration(
              filled: true,
              label: Text("Note"),
            ),
            maxLines: null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Updating note..."),
                    behavior: SnackBarBehavior.floating,
                  ));

                  try {
                    await save();

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Successfully updated note"),
                      behavior: SnackBarBehavior.floating,
                    ));
                  } catch (error) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        "Error updating note: $error",
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                    ));
                  }
                },
                child: const Text("Save"),
              ),
            ].withSpaceBetween(width: 10),
          )
        ].withSpaceBetween(height: 10),
      ),
    );
  }
}
