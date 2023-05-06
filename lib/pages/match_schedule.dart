import 'dart:convert';

import 'package:chips_input/chips_input.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/role_exclusive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletons/skeletons.dart';
import 'package:http/http.dart' as http;

import '../reusable/navigation_drawer.dart';

class MatchSchedulePage extends StatefulWidget {
  const MatchSchedulePage({super.key});

  @override
  State<MatchSchedulePage> createState() => _MatchSchedulePageState();
}

class _MatchSchedulePageState extends State<MatchSchedulePage> {
  List<int> _teamsFilter = [];
  CompletionFilter completionFilter = CompletionFilter.any;

  GameMatchIdentity? nextMatch;

  TournamentSchedule? tournamentSchedule;
  ScoutSchedule? scoutSchedule;
  Map<String, String?>? isScouted;

  Future<void> fetchData() async {
    final outputs = await Future.wait([
      TournamentSchedule.fromServer(
        (await getServerAuthority())!,
        (await SharedPreferences.getInstance()).getString('tournament')!,
      ),
      getScoutSchedule(),
      getScoutedStatuses(),
    ]);

    final fetchedTournamentSchedule = outputs[0] as TournamentSchedule;
    final fetchedScoutSchedule = outputs[1] as ScoutSchedule;
    final fetchedIsScouted = outputs[2] as Map<String, String?>;

    fetchedTournamentSchedule.matches
        .sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));

    final ScheduleMatch fetchedLastScoutedMatch =
        fetchedTournamentSchedule.matches.lastWhere((match) => [
              fetchedIsScouted["${match.identity.toMediumKey()}_0"],
              fetchedIsScouted["${match.identity.toMediumKey()}_1"],
              fetchedIsScouted["${match.identity.toMediumKey()}_2"],
              fetchedIsScouted["${match.identity.toMediumKey()}_3"],
              fetchedIsScouted["${match.identity.toMediumKey()}_4"],
              fetchedIsScouted["${match.identity.toMediumKey()}_5"],
            ].any((e) => e != null));

    final ScheduleMatch? nextScheduleMatch = fetchedTournamentSchedule.matches
        .cast<ScheduleMatch?>()
        .singleWhere(
          (match) =>
              match?.ordinalNumber == fetchedLastScoutedMatch.ordinalNumber + 1,
          orElse: () => null,
        );

    setState(() {
      if (nextScheduleMatch?.identity.toMediumKey() !=
          nextMatch?.toMediumKey()) {
        nextMatch = nextScheduleMatch?.identity;
      }

      tournamentSchedule = fetchedTournamentSchedule;
      scoutSchedule = fetchedScoutSchedule;
      isScouted = fetchedIsScouted;
    });
  }

  @override
  void initState() {
    super.initState();

    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Schedule"),
        actions: [
          RoleExclusive(
            roles: const ["8033_scouting_lead"],
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/edit_scout_schedule");
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
          RoleExclusive(
            roles: const ["8033_scouting_lead"],
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
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Up next",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 5),
                          nextMatch == null
                              ? const SkeletonLine(
                                  style: SkeletonLineStyle(
                                    width: 50,
                                    height: 20,
                                  ),
                                )
                              : Text(
                                  nextMatch!.getShortLocalizedDescription(),
                                ),
                        ],
                      ),
                    ])
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
      body: PageBody(
        bottom: false,
        padding: EdgeInsets.zero,
        child: (tournamentSchedule == null ||
                scoutSchedule == null ||
                isScouted == null)
            ? Column(children: const [LinearProgressIndicator()])
            : RefreshIndicator(
                onRefresh: () => fetchData(),
                child: ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  addAutomaticKeepAlives: true,
                  // itemExtent: 190,
                  itemBuilder: (context, index) {
                    ScheduleMatch match = tournamentSchedule!.matches[index];

                    List<String?> scouted = [
                      isScouted!["${match.identity.toMediumKey()}_0"],
                      isScouted!["${match.identity.toMediumKey()}_1"],
                      isScouted!["${match.identity.toMediumKey()}_2"],
                      isScouted!["${match.identity.toMediumKey()}_3"],
                      isScouted!["${match.identity.toMediumKey()}_4"],
                      isScouted!["${match.identity.toMediumKey()}_5"],
                    ];

                    if (!_teamsFilter
                            .every((team) => match.teams.contains(team)) &&
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
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 13, 10, 13),
                                      child: Text(
                                        match.identity.getLocalizedDescription(
                                            includeTournament: false),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
                                    ),
                                    if (!scouted.contains(null))
                                      const ScoutedFlag(),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed(
                                          "/match_predictor",
                                          arguments: {
                                            'red1': match.teams[0].toString(),
                                            'red2': match.teams[1].toString(),
                                            'red3': match.teams[2].toString(),
                                            'blue1': match.teams[3].toString(),
                                            'blue2': match.teams[4].toString(),
                                            'blue3': match.teams[5].toString(),
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.psychology),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed(
                                          "/match_suggestions",
                                          arguments: {
                                            'teams': <String, int>{
                                              'red1': match.teams[0],
                                              'red2': match.teams[1],
                                              'red3': match.teams[2],
                                              'blue1': match.teams[3],
                                              'blue2': match.teams[4],
                                              'blue3': match.teams[5],
                                            },
                                            'matchIdentity': match.identity,
                                            'matchType': match.identity.type,
                                          },
                                        );
                                      },
                                      icon: const Icon(Icons.assistant),
                                    ),
                                  ],
                                ),
                                AllianceRow(
                                  alliance: Alliance.red,
                                  items: [
                                    AllianceRowItem(
                                      scouted: scouted[0] != null,
                                      longMatchKey:
                                          "${match.identity.toMediumKey()}_0",
                                      team: match.teams[0],
                                      scout: scoutSchedule!.getScoutsForMatch(
                                          match.ordinalNumber)[0],
                                      warnings: getWarnings(
                                        scouted,
                                        0,
                                        scoutSchedule!.getScoutsForMatch(
                                            match.ordinalNumber),
                                      ),
                                    ),
                                    AllianceRowItem(
                                      scouted: scouted[1] != null,
                                      longMatchKey:
                                          "${match.identity.toMediumKey()}_1",
                                      team: match.teams[1],
                                      scout: scoutSchedule!.getScoutsForMatch(
                                          match.ordinalNumber)[1],
                                      warnings: getWarnings(
                                        scouted,
                                        1,
                                        scoutSchedule!.getScoutsForMatch(
                                            match.ordinalNumber),
                                      ),
                                    ),
                                    AllianceRowItem(
                                      scouted: scouted[2] != null,
                                      longMatchKey:
                                          "${match.identity.toMediumKey()}_2",
                                      team: match.teams[2],
                                      scout: scoutSchedule!.getScoutsForMatch(
                                          match.ordinalNumber)[2],
                                      warnings: getWarnings(
                                        scouted,
                                        2,
                                        scoutSchedule!.getScoutsForMatch(
                                            match.ordinalNumber),
                                      ),
                                    ),
                                  ],
                                ),
                                AllianceRow(
                                  alliance: Alliance.blue,
                                  items: [
                                    AllianceRowItem(
                                      scouted: scouted[3] != null,
                                      longMatchKey:
                                          "${match.identity.toMediumKey()}_3",
                                      team: match.teams[3],
                                      scout: scoutSchedule!.getScoutsForMatch(
                                          match.ordinalNumber)[3],
                                      warnings: getWarnings(
                                        scouted,
                                        3,
                                        scoutSchedule!.getScoutsForMatch(
                                            match.ordinalNumber),
                                      ),
                                    ),
                                    AllianceRowItem(
                                      scouted: scouted[4] != null,
                                      longMatchKey:
                                          "${match.identity.toMediumKey()}_4",
                                      team: match.teams[4],
                                      scout: scoutSchedule!.getScoutsForMatch(
                                          match.ordinalNumber)[4],
                                      warnings: getWarnings(
                                        scouted,
                                        4,
                                        scoutSchedule!.getScoutsForMatch(
                                            match.ordinalNumber),
                                      ),
                                    ),
                                    AllianceRowItem(
                                      scouted: scouted[5] != null,
                                      longMatchKey:
                                          "${match.identity.toMediumKey()}_5",
                                      team: match.teams[5],
                                      scout: scoutSchedule!.getScoutsForMatch(
                                          match.ordinalNumber)[5],
                                      warnings: getWarnings(
                                        scouted,
                                        5,
                                        scoutSchedule!.getScoutsForMatch(
                                            match.ordinalNumber),
                                      ),
                                    ),
                                  ],
                                ),
                              ]),
                        ),
                      ),
                    );
                  },
                  itemCount: tournamentSchedule!.matches.length,
                ),
              ),
      ),
      drawer: const GlobalNavigationDrawer(),
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
    this.longMatchKey,
    required this.scouted,
  });

  final int team;
  final String scout;
  final List<String> warnings;
  final String? longMatchKey;
  final bool scouted;
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
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .pushNamed('/alliance', arguments: <String, dynamic>{
          'teams': items.map((e) => e.team).toList(),
        });
      },
      child: Container(
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
      ),
    );
  }

  Widget column(BuildContext context, AllianceRowItem item,
      CrossAxisAlignment alignment) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
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
              if (item.scouted)
                RoleExclusive(
                  roles: const ["8033_scouting_lead"],
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/raw_scout_report',
                          arguments: <String, dynamic>{
                            'longMatchKey': item.longMatchKey,
                            'team': item.team,
                          });
                    },
                    icon: const Icon(Icons.data_object),
                    visualDensity: VisualDensity.compact,
                  ),
                )
            ],
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
