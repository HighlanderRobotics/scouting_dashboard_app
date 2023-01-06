import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_overview_analysis.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

import '../reusable/navigation_drawer.dart';

class TeamLookup extends StatefulWidget {
  const TeamLookup({super.key});

  @override
  State<TeamLookup> createState() => _TeamLookupState();
}

class _TeamLookupState extends State<TeamLookup> {
  String teamFieldValue = "";
  int? teamNumberForAnalysis;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Team Lookup")),
      body: ScrollablePageBody(children: [
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            label: Text("Team #"),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              teamFieldValue = value;
              if (int.tryParse(value) != null) {
                teamNumberForAnalysis = int.parse(value);
              }
            });
          },
        ),
        const SizedBox(height: 24),
        if (teamNumberForAnalysis != null)
          AnalysisOverview(
            analysis: TeamOverviewAnalysis(team: teamNumberForAnalysis!),
            teamNumber: teamNumberForAnalysis!,
          )
      ]),
      drawer: const NavigationDrawer(),
    );
  }
}

class AnalysisOverview extends AnalysisVisualization {
  const AnalysisOverview({
    Key? key,
    required TeamOverviewAnalysis analysis,
    required this.teamNumber,
  }) : super(key: key, analysisFunction: analysis);

  final int teamNumber;

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverviewMetricsList(
          metricCategories: metricCategories
              .map((category) => MetricCategory(
                    categoryName: category.localizedName,
                    metricTiles: category.metrics
                        .map(
                          (metric) => MetricTile(
                            value: (() {
                              try {
                                return metric.valueVizualizationBuilder(
                                    snapshot.data['metrics'][metric.path]);
                              } catch (error) {
                                return "--";
                              }
                            })(),
                            label: metric.abbreviatedLocalizedName,
                          ),
                        )
                        .toList(),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed("/team_lookup_details", arguments: {
                        'category': category,
                        'team': teamNumber,
                      });
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        Text(
          "Notes",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        if ((snapshot.data['notes'] as List).isNotEmpty)
          NotesList(
              notes: ((snapshot.data['notes'] as List)
                      .cast<Map<String, dynamic>>())
                  .map((note) => Note(
                      matchName: GameMatchIdentity.fromLongKey(note['matchKey'])
                          .getLocalizedDescription(includeTournament: false),
                      noteBody: note['notes']))
                  .toList()
                  .cast<Note>()),
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
      children: notes
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

class OverviewMetricsList extends StatelessWidget {
  const OverviewMetricsList({
    Key? key,
    this.metricCategories = const [],
  }) : super(key: key);

  final List<MetricCategory> metricCategories;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: metricCategories
          .expand((element) => [element, const SizedBox(height: 15)])
          .take(metricCategories.length * 2 - 1)
          .toList(),
    );
  }
}

class MetricCategory extends StatelessWidget {
  const MetricCategory({
    Key? key,
    required this.categoryName,
    this.metricTiles = const <MetricTile>[],
    this.onTap,
  }) : super(key: key);

  final String categoryName;
  final List<MetricTile> metricTiles;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: Theme.of(context).textTheme.titleMedium!.merge(
                              TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: metricTiles
                            .expand((element) =>
                                [element, const SizedBox(width: 10)])
                            .take(metricTiles.length * 2 - 1)
                            .toList(),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.navigate_next,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    Key? key,
    required this.value,
    required this.label,
  }) : super(key: key);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall!.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium!.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
