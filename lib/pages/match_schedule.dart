import 'dart:convert';

import 'package:chips_input/chips_input.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/role_exclusive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletons/skeletons.dart';
import 'package:http/http.dart' as http;

import '../reusable/navigation_drawer.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  List<int> _teamsFilter = [];
  CompletionFilter completionFilter = CompletionFilter.any;

  RefreshController refreshController =
      RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Schedule"),
        actions: [
          RoleExclusive(
            role: "scouting_lead",
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/edit_scout_schedule");
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
          RoleExclusive(
            role: "scouting_lead",
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/scout_schedule_qr");
              },
              icon: const Icon(Icons.qr_code),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(177),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    teamsInput(),
                    const SizedBox(height: 16),
                    Text(
                      "Completion",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      FilterChip(
                        label: const Text("Upcoming"),
                        selected: completionFilter == CompletionFilter.upcoming,
                        onSelected: (value) {
                          if (completionFilter == CompletionFilter.upcoming) {
                            setState(() {
                              completionFilter = CompletionFilter.any;
                            });
                            return;
                          }

                          setState(() {
                            completionFilter = CompletionFilter.upcoming;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text("Finished"),
                        selected: completionFilter == CompletionFilter.finished,
                        onSelected: (value) {
                          if (completionFilter == CompletionFilter.finished) {
                            setState(() {
                              completionFilter = CompletionFilter.any;
                            });
                            return;
                          }

                          setState(() {
                            completionFilter = CompletionFilter.finished;
                          });
                        },
                      ),
                    ])
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        child: FutureBuilder(future: (() async {
          final TournamentSchedule tournamentSchedule =
              await TournamentSchedule.fromServer(
            (await getServerAuthority())!,
            (await SharedPreferences.getInstance()).getString('tournament')!,
          );

          final List<Map<String, dynamic>> isScoutedResponse = (jsonDecode(
                  utf8.decode((await http.get(Uri.http(
                          (await getServerAuthority())!,
                          '/API/manager/isScouted', {
            'tournamentKey':
                (await SharedPreferences.getInstance()).getString('tournament'),
          })))
                      .bodyBytes)) as List<dynamic>)
              .cast();

          Map<String, String?> isScoutedElegante = {};

          for (var response in isScoutedResponse) {
            isScoutedElegante[response['key']] = response['name'];
          }

          return {
            'tournamentSchedule': tournamentSchedule,
            'scoutSchedule': await getScoutSchedule(),
            'isScouted': isScoutedElegante,
          };
        })(), builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final TournamentSchedule tournamentSchedule =
              snapshot.data!['tournamentSchedule'] as TournamentSchedule;
          final ScoutSchedule scoutSchedule =
              snapshot.data!['scoutSchedule'] as ScoutSchedule;
          final Map<String, String?> isScoutedResponse =
              snapshot.data!['isScouted'] as Map<String, String?>;

          debugPrint(snapshot.toString());

          return SmartRefresher(
            controller: refreshController,
            onRefresh: () {
              refreshController.refreshCompleted();
              setState(() {});
            },
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              addAutomaticKeepAlives: true,
              // itemExtent: 190,
              itemBuilder: (context, index) {
                ScheduleMatch match = tournamentSchedule.matches[index];

                List<String?> scouted = [
                  isScoutedResponse["${match.identity.toMediumKey()}_0"],
                  isScoutedResponse["${match.identity.toMediumKey()}_1"],
                  isScoutedResponse["${match.identity.toMediumKey()}_2"],
                  isScoutedResponse["${match.identity.toMediumKey()}_3"],
                  isScoutedResponse["${match.identity.toMediumKey()}_4"],
                  isScoutedResponse["${match.identity.toMediumKey()}_5"],
                ];

                if (!match.teams.any((team) => _teamsFilter.contains(team)) &&
                    _teamsFilter.isNotEmpty) {
                  return Container();
                }

                if (completionFilter == CompletionFilter.finished &&
                    !scouted.any((report) => report != null)) {
                  return Container();
                }

                if (completionFilter == CompletionFilter.upcoming &&
                    scouted.any((report) => report != null)) {
                  return Container();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 13, 10, 13),
                                  child: Text(
                                    match.identity.getLocalizedDescription(
                                        includeTournament: false),
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                                if (!scouted.contains(null)) const ScoutedFlag()
                              ],
                            ),
                            AllianceRow(
                              alliance: Alliance.red,
                              items: [
                                AllianceRowItem(
                                  team: match.teams[0],
                                  scout: scoutSchedule.getScoutsForMatch(
                                      match.ordinalNumber)[0],
                                  warnings: getWarnings(
                                    scouted,
                                    0,
                                    scoutSchedule
                                        .getScoutsForMatch(match.ordinalNumber),
                                  ),
                                ),
                                AllianceRowItem(
                                  team: match.teams[1],
                                  scout: scoutSchedule.getScoutsForMatch(
                                      match.ordinalNumber)[1],
                                  warnings: getWarnings(
                                    scouted,
                                    1,
                                    scoutSchedule
                                        .getScoutsForMatch(match.ordinalNumber),
                                  ),
                                ),
                                AllianceRowItem(
                                  team: match.teams[2],
                                  scout: scoutSchedule.getScoutsForMatch(
                                      match.ordinalNumber)[2],
                                  warnings: getWarnings(
                                    scouted,
                                    2,
                                    scoutSchedule
                                        .getScoutsForMatch(match.ordinalNumber),
                                  ),
                                ),
                              ],
                            ),
                            AllianceRow(
                              alliance: Alliance.blue,
                              items: [
                                AllianceRowItem(
                                  team: match.teams[3],
                                  scout: scoutSchedule.getScoutsForMatch(
                                      match.ordinalNumber)[3],
                                  warnings: getWarnings(
                                    scouted,
                                    3,
                                    scoutSchedule
                                        .getScoutsForMatch(match.ordinalNumber),
                                  ),
                                ),
                                AllianceRowItem(
                                  team: match.teams[4],
                                  scout: scoutSchedule.getScoutsForMatch(
                                      match.ordinalNumber)[4],
                                  warnings: getWarnings(
                                    scouted,
                                    4,
                                    scoutSchedule
                                        .getScoutsForMatch(match.ordinalNumber),
                                  ),
                                ),
                                AllianceRowItem(
                                  team: match.teams[5],
                                  scout: scoutSchedule.getScoutsForMatch(
                                      match.ordinalNumber)[5],
                                  warnings: getWarnings(
                                    scouted,
                                    5,
                                    scoutSchedule
                                        .getScoutsForMatch(match.ordinalNumber),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                    ),
                  ),
                );
              },
              itemCount: tournamentSchedule.matches.length,
            ),
          );
        }),
      ),
      drawer: const NavigationDrawer(),
    );
  }

  ChipsInput<int> teamsInput() {
    return ChipsInput(
      chipBuilder: ((context, state, data) {
        return InputChip(
          label: Text(data.toString()),
          onDeleted: () => state.deleteChip(data),
          backgroundColor: Theme.of(context).colorScheme.background,
          labelStyle: Theme.of(context).textTheme.labelLarge!.merge(TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          deleteIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
        );
      }),
      findSuggestions: ((query) {
        if (int.tryParse(query) != null) {
          return <int>[int.parse(query)];
        }

        return <int>[];
      }),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        label: const Text("Filter by teams"),
        constraints: const BoxConstraints.tightFor(height: 64),
        contentPadding: _teamsFilter.isEmpty
            ? const EdgeInsets.fromLTRB(12, 16, 12, 16)
            : const EdgeInsets.all(12),
      ),
      onChanged: (value) {
        setState(() {
          _teamsFilter = value;
        });
      },
      suggestionBuilder: (context, data) {
        return ListTile(title: Text(data.toString()));
      },
      maxChips: 3,
      keyboardType: TextInputType.number,
    );
  }

  List<String> getWarnings(
      List<String?> scouted, int scoutIndex, List<String> matchScheduleScouts) {
    return [
      if (scouted.any((scout) => scout != null) && scouted[scoutIndex] == null)
        "Must scan",
      if (scouted[scoutIndex] != null &&
          matchScheduleScouts[scoutIndex] != scouted[scoutIndex])
        "By ${scouted[scoutIndex]}",
    ];
  }
}

class AllianceRowItem {
  const AllianceRowItem({
    required this.team,
    required this.scout,
    this.warnings = const [],
  });

  final int team;
  final String scout;
  final List<String> warnings;
}

class AllianceRow extends StatelessWidget {
  const AllianceRow({
    Key? key,
    required this.alliance,
    required this.items,
  }) : super(key: key);

  final Alliance alliance;
  final List<AllianceRowItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: alliance == Alliance.red ? redAlliance : blueAlliance,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            column(context, items[0], CrossAxisAlignment.start),
            column(context, items[1], CrossAxisAlignment.center),
            column(context, items[2], CrossAxisAlignment.end),
          ],
        ),
      ),
    );
  }

  Widget column(BuildContext context, AllianceRowItem item,
      CrossAxisAlignment alignment) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed("/team_lookup", arguments: {
                'team': item.team,
              });
            },
            child: Text(
              item.team.toString(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Text(
            item.scout,
            style: Theme.of(context).textTheme.labelSmall!.merge(
                  TextStyle(
                    color: alliance == Alliance.red
                        ? onRedAlliance
                        : onBlueAlliance,
                  ),
                ),
            textAlign: {
              CrossAxisAlignment.start: TextAlign.start,
              CrossAxisAlignment.center: TextAlign.center,
              CrossAxisAlignment.end: TextAlign.end,
            }[alignment],
          ),
          LayoutBuilder(builder: (context, constraints) {
            return Column(
              crossAxisAlignment: alignment,
              children: item.warnings
                  .map(
                    (warning) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error,
                          size: 20,
                          color: warningText,
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(2, 2, 0, 0),
                            child: Text(
                              warning,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .merge(TextStyle(color: warningText)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            );
          })
        ],
      ),
    );
  }
}

enum CompletionFilter {
  any,
  upcoming,
  finished,
}

enum Alliance { red, blue }

class ScoutedFlag extends StatelessWidget {
  const ScoutedFlag({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.all(
            Radius.circular(4),
          )),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
        child: Text(
          "Scouted",
          style: Theme.of(context).textTheme.labelMedium!.merge(
                TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
        ),
      ),
    );
  }
}
