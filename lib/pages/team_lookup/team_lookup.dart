import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_categories_analysis.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_notes_analysis.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/tabs/team_lookup_categories.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/tabs/team_lookup_notes.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

import '../../reusable/navigation_drawer.dart';

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Team Lookup"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(129),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 19, 24, 8),
                  child: TextField(
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
                ),
                TabBar(
                  tabs: const [
                    Tab(text: "Categories"),
                    Tab(text: "Notes"),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  labelStyle: Theme.of(context).textTheme.titleSmall,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  indicatorPadding: const EdgeInsets.fromLTRB(2, 46, 2, 0),
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
        body: teamNumberForAnalysis == null
            ? const PageBody(
                child: Center(
                  child: Text("Enter a team number"),
                ),
              )
            : Container(
                color: Theme.of(context).colorScheme.background,
                child: TabBarView(
                  children: [
                    TeamLookupCategoriesVizualization(
                      function: TeamLookupCategoriesAnalysis(
                          team: teamNumberForAnalysis!),
                    ),
                    TeamLookupNotesVizualization(
                      function:
                          TeamLookupNotesAnalysis(team: teamNumberForAnalysis!),
                    ),
                  ],
                ),
              ),
        drawer: const NavigationDrawer(),
      ),
    );
  }
}

// class AnalysisOverview extends AnalysisVisualization {
//   const AnalysisOverview({
//     Key? key,
//     required TeamOverviewAnalysis analysis,
//     required this.teamNumber,
//   }) : super(key: key, analysisFunction: analysis);

//   final int teamNumber;

//   @override
//   Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         OverviewMetricsList(
//           metricCategories: metricCategories
//               .map((category) => MetricCategory(
//                     categoryName: category.localizedName,
//                     metricTiles: category.metrics
//                         .map(
//                           (metric) => MetricTile(
//                             value: (() {
//                               try {
//                                 return metric.valueVizualizationBuilder(
//                                     snapshot.data['metrics'][metric.path]);
//                               } catch (error) {
//                                 return "--";
//                               }
//                             })(),
//                             label: metric.abbreviatedLocalizedName,
//                           ),
//                         )
//                         .toList(),
//                     onTap: () {
//                       Navigator.of(context)
//                           .pushNamed("/team_lookup_details", arguments: {
//                         'category': category,
//                         'team': teamNumber,
//                       });
//                     },
//                   ))
//               .toList(),
//         ),
//         const SizedBox(height: 20),
//         Text(
//           "Notes",
//           style: Theme.of(context).textTheme.headlineSmall,
//         ),
//         const SizedBox(height: 8),
//         if ((snapshot.data['notes'] as List).isNotEmpty)
//           NotesList(
//               notes: ((snapshot.data['notes'] as List)
//                       .cast<Map<String, dynamic>>())
//                   .map((note) => Note(
//                       matchName: GameMatchIdentity.fromLongKey(note['matchKey'])
//                           .getLocalizedDescription(includeTournament: false),
//                       noteBody: note['notes']))
//                   .toList()
//                   .cast<Note>()),
//       ],
//     );
//   }
// }
