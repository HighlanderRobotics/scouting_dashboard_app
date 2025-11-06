import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_breakdowns_analysis.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_categories_analysis.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_notes_analysis.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/edit_team_lookup_flag.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/tabs/team_lookup_breakdowns.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/tabs/team_lookup_categories.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/tabs/team_lookup_notes.dart';
import 'package:scouting_dashboard_app/reusable/debouncer.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../reusable/navigation_drawer.dart';

class TeamLookupPage extends StatefulWidget {
  const TeamLookupPage({super.key});

  @override
  State<TeamLookupPage> createState() => _TeamLookupPageState();
}

class _TeamLookupPageState extends State<TeamLookupPage> {
  final debouncer = Debouncer(delay: const Duration(milliseconds: 200));
  String teamFieldValue = "";
  TextEditingController? teamFieldController;
  int? teamNumberForAnalysis;

  int flagChangeCount = 0;
  int updateIncrement = 0;

  @override
  Widget build(BuildContext context) {
    if (teamFieldController == null) {
      teamFieldController = TextEditingController(
        text: ((ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>?)?['team'] as int?)
            ?.toString(),
      );

      int? teamNumberFromRoute = (ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>?)?['team'];

      if (teamNumberFromRoute != null) {
        setState(() {
          teamFieldValue = teamNumberFromRoute.toString();
          teamNumberForAnalysis = teamNumberFromRoute;
        });
      }
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Team Lookup"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(129),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 19, 24, 8),
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text("Team #"),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          debouncer.run(() {
                            setState(() {
                              teamFieldValue = value;
                              if (int.tryParse(value) != null) {
                                teamNumberForAnalysis = int.parse(value);
                              } else {
                                teamNumberForAnalysis = null;
                              }
                              updateIncrement++;
                            });
                          });
                        },
                        controller: teamFieldController,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/edit_team_lookup_flag',
                              arguments: EditTeamLookupFlagArgs(
                                team: int.tryParse(teamFieldValue) ?? 8033,
                                onChange: (newFlag) {
                                  setState(() {
                                    flagChangeCount += 1;
                                  });
                                },
                              ),
                            );
                          },
                          child: TeamLookupFlag(
                            team: teamFieldValue,
                            key: Key('flag-$flagChangeCount'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: const [
                    Tab(text: "Categories"),
                    Tab(text: "Breakdowns"),
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
                      updateIncrement: updateIncrement,
                      function: TeamLookupCategoriesAnalysis(
                        team: teamNumberForAnalysis!,
                      ),
                    ),
                    TeamLookupBreakdownsVizualization(
                      updateIncrement: updateIncrement,
                      function: TeamLookupBreakdownsAnalysis(
                        team: teamNumberForAnalysis!,
                      ),
                    ),
                    TeamLookupNotesVizualization(
                      key: GlobalKey(),
                      updateIncrement: updateIncrement,
                      function: TeamLookupNotesAnalysis(
                        team: teamNumberForAnalysis!,
                      ),
                    ),
                  ],
                ),
              ),
        drawer: ((ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?)?['team'] as int?) ==
                null
            ? const GlobalNavigationDrawer()
            : null,
      ),
    );
  }
}

class TeamLookupFlag extends StatefulWidget {
  const TeamLookupFlag({
    super.key,
    required this.team,
  });

  final String team;

  @override
  State<TeamLookupFlag> createState() => _TeamLookupFlagState();
}

class _TeamLookupFlagState extends State<TeamLookupFlag> {
  SharedPreferences? prefs;
  String? loadingTeam;

  Future<void> load() async {
    loadingTeam = widget.team;

    final sp = await SharedPreferences.getInstance();
    setState(() {
      prefs = sp;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loadingTeam != widget.team) load();

    if (prefs == null ||
        int.tryParse(widget.team) == null ||
        prefs!.getString('team_lookup_flag') == null) {
      return Container();
    }
    return NetworkFlag(
      team: int.parse(widget.team),
      flag: FlagConfiguration.fromJson(
        jsonDecode(
          prefs!.getString('team_lookup_flag')!,
        ),
      ),
    );
  }
}
