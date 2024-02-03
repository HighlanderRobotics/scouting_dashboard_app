import 'dart:convert';

import 'package:chips_input/chips_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/team_per_match.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/user_profile.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletons/skeletons.dart';

import '../reusable/navigation_drawer.dart';

import 'package:http/http.dart' as http;

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

  String? initialError;
  String? noScheduleTournament;

  List<Map<String, dynamic>>? teamsInTournament;

  bool isDataFetched = false;
  bool? isScoutingLead;
  Tournament? currentTournament;

  bool fabVisible = false;

  Future<void> checkRole() async {
    final profile = await lovatAPI.getUserProfile();

    setState(() {
      isScoutingLead = profile.role == UserRole.scoutingLead;
    });
  }

  Future<void> checkTournament() async {
    final current = await Tournament.getCurrent();

    setState(() {
      currentTournament = current;
    });
  }

  Future<void> fetchData() async {
    List<dynamic> outputs = [];
    try {
      outputs = await Future.wait(
        [
          TournamentSchedule.fromServer(
            (await getServerAuthority())!,
            (await SharedPreferences.getInstance()).getString('tournament')!,
          ),
          // getScoutSchedule(),
          getScoutedStatuses(),
        ],
      );

      final fetchedTournamentSchedule = outputs[0] as TournamentSchedule;
      final fetchedScoutSchedule = outputs[1] as ScoutSchedule;
      final fetchedIsScouted = outputs[2] as Map<String, String?>;

      fetchedTournamentSchedule.matches
          .sort((a, b) => a.ordinalNumber.compareTo(b.ordinalNumber));

      ScheduleMatch? nextScheduleMatch;

      try {
        final ScheduleMatch fetchedLastScoutedMatch =
            fetchedTournamentSchedule.matches.lastWhere((match) => [
                  fetchedIsScouted["${match.identity.toMediumKey()}_0"],
                  fetchedIsScouted["${match.identity.toMediumKey()}_1"],
                  fetchedIsScouted["${match.identity.toMediumKey()}_2"],
                  fetchedIsScouted["${match.identity.toMediumKey()}_3"],
                  fetchedIsScouted["${match.identity.toMediumKey()}_4"],
                  fetchedIsScouted["${match.identity.toMediumKey()}_5"],
                ].any((e) => e != null));

        nextScheduleMatch = fetchedTournamentSchedule.matches
            .cast<ScheduleMatch?>()
            .singleWhere(
              (match) =>
                  match?.ordinalNumber ==
                  fetchedLastScoutedMatch.ordinalNumber + 1,
              orElse: () => null,
            );
      } catch (error) {
        print(error);

        nextScheduleMatch = fetchedTournamentSchedule.matches.first;
      }

      setState(() {
        if (nextScheduleMatch?.identity.toMediumKey() !=
            nextMatch?.toMediumKey()) {
          nextMatch = nextScheduleMatch?.identity;
        }

        tournamentSchedule = fetchedTournamentSchedule;
        scoutSchedule = fetchedScoutSchedule;
        isScouted = fetchedIsScouted;

        isDataFetched = true;
      });
    } catch (error) {
      final prefs = await SharedPreferences.getInstance();

      if (error == "No matches found for ${prefs.getString('tournament')}") {
        setState(() {
          noScheduleTournament = prefs.getString('tournament_localized');
        });
      }

      setState(() {
        initialError = error.toString();
      });
    }
  }

  Future<void> fetchTeamsInTournament() async {
    final prefs = await SharedPreferences.getInstance();

    final response = await http.get(Uri.http(
        (await getServerAuthority())!, "/API/manager/getTeamsInTournament", {
      'tournamentKey': prefs.getString("tournament")!,
    }));

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error fetching teams: ${response.statusCode} ${response.reasonPhrase}: ${response.body}",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );

      return;
    }

    setState(() {
      teamsInTournament =
          jsonDecode(response.body).cast<Map<String, dynamic>>();
    });
  }

  @override
  void initState() {
    super.initState();

    fetchData();
    checkRole();
    checkTournament();
    fetchTeamsInTournament();
  }

  final scrollController = ScrollController();
  final nextMatchKey = GlobalKey();

  void jumpToNextMatch() {
    Scrollable.ensureVisible(nextMatchKey.currentContext!);
  }

  @override
  Widget build(BuildContext context) {
    List<ScheduleMatch>? filteredMatches;

    if (isDataFetched) {
      filteredMatches = tournamentSchedule!.matches.where((match) {
        List<String?> scouted = [
          isScouted!["${match.identity.toMediumKey()}_0"],
          isScouted!["${match.identity.toMediumKey()}_1"],
          isScouted!["${match.identity.toMediumKey()}_2"],
          isScouted!["${match.identity.toMediumKey()}_3"],
          isScouted!["${match.identity.toMediumKey()}_4"],
          isScouted!["${match.identity.toMediumKey()}_5"],
        ];

        if (!_teamsFilter.every((team) => match.teams.contains(team)) &&
            _teamsFilter.isNotEmpty) {
          return false;
        }

        if (completionFilter == CompletionFilter.finished &&
            !scouted.any((report) => report != null)) {
          return false;
        }

        if (completionFilter == CompletionFilter.upcoming &&
            scouted.any((report) => report != null)) {
          return false;
        }

        return true;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Schedule"),
        actions: [
          if ((isScoutingLead ?? false) && currentTournament != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/edit_scout_schedule");
              },
              icon: const Icon(Icons.edit_outlined),
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
                      GestureDetector(
                        onTap: isDataFetched && nextMatch != null
                            ? jumpToNextMatch
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Up next",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 5),
                            isDataFetched
                                ? Text(
                                    nextMatch?.getShortLocalizedDescription() ??
                                        "No more",
                                  )
                                : const SkeletonLine(
                                    style: SkeletonLineStyle(
                                      width: 50,
                                      height: 20,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ])
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !fabVisible
          ? null
          : FloatingActionButton(
              tooltip: "Jump to top",
              onPressed: () {
                setState(() {
                  fabVisible = false;
                });

                scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            ),
      body: PageBody(
        bottom: false,
        padding: EdgeInsets.zero,
        child: noScheduleTournament != null
            ? NoScheduleMessage(noScheduleTournament!)
            : initialError != null
                ? FriendlyErrorView(
                    errorMessage: initialError,
                    onRetry: () {
                      setState(() {
                        initialError = null;
                      });
                      fetchData();
                    },
                  )
                : (tournamentSchedule == null ||
                        scoutSchedule == null ||
                        isScouted == null)
                    ? const SkeletonMatches()
                    : NotificationListener<ScrollUpdateNotification>(
                        onNotification: (notification) {
                          final FocusScopeNode focusScope =
                              FocusScope.of(context);
                          if (notification.dragDetails != null &&
                              focusScope.hasFocus &&
                              !focusScope.hasPrimaryFocus) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          }

                          updateFabVisibility(notification);

                          return false;
                        },
                        child: Matches(
                          onRefresh: () => fetchData(),
                          isScouted: isScouted,
                          scrollController: scrollController,
                          filteredMatches: filteredMatches,
                          nextMatch: nextMatch,
                          nextMatchKey: nextMatchKey,
                          isScoutingLead: isScoutingLead,
                          scoutSchedule: scoutSchedule,
                        ),
                      ),
      ),
      drawer: const GlobalNavigationDrawer(),
    );
  }

  Future<void> updateFabVisibility(
      ScrollUpdateNotification notification) async {
    if (notification.dragDetails != null) {
      if (notification.dragDetails!.delta.dy > 0 &&
          scrollController.offset > 1000 &&
          !fabVisible) {
        setState(() {
          fabVisible = true;
        });
      }

      if (notification.dragDetails!.delta.dy < 0 && fabVisible) {
        setState(() {
          fabVisible = false;
        });
      }

      if (scrollController.offset < 1000 && fabVisible) {
        setState(() {
          fabVisible = false;
        });
      }
    }
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
          return <int>[
            int.parse(query),
            ...(teamsInTournament
                    ?.map((e) => e['teamNumber'])
                    .cast<int>()
                    .where((e) => e.toString().startsWith(query)) ??
                [])
          ];
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
}

class SkeletonMatches extends StatelessWidget {
  const SkeletonMatches({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24).copyWith(bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            skeletonMatch(),
            skeletonMatch(),
            skeletonMatch(),
            skeletonMatch(),
          ].withSpaceBetween(height: 20),
        ),
      ),
    );
  }

  Widget skeletonMatch() {
    return SkeletonAvatar(
      style: SkeletonAvatarStyle(
        height: 170,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class AllianceRowItem {
  const AllianceRowItem({
    required this.team,
    this.scout,
    this.warnings = const [],
    this.longMatchKey,
    required this.scouted,
  });

  final int team;
  final String? scout;
  final List<String> warnings;
  final String? longMatchKey;
  final bool scouted;
}

class AllianceRow extends StatelessWidget {
  const AllianceRow({
    Key? key,
    required this.alliance,
    required this.items,
    this.isScoutingLead,
  }) : super(key: key);

  final Alliance alliance;
  final List<AllianceRowItem> items;
  final bool? isScoutingLead;

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
        color: alliance == Alliance.red
            ? Theme.of(context).colorScheme.redAlliance
            : Theme.of(context).colorScheme.blueAlliance,
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
              CupertinoContextMenu.builder(
                enableHapticFeedback: true,
                actions: [
                  CupertinoContextMenuAction(
                    child: const Text("Team lookup"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .pushNamed("/team_lookup", arguments: {
                        'team': item.team,
                      });
                    },
                  ),
                  if (item.scouted && item.longMatchKey != null)
                    CupertinoContextMenuAction(
                      child: const Text("Per-match metrics"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(
                          '/team_per_match',
                          arguments: TeamPerMatchArgs(
                            longMatchKey: item.longMatchKey!,
                            teamNumber: item.team,
                          ),
                        );
                      },
                    ),
                  if (item.scouted && (isScoutingLead ?? false))
                    CupertinoContextMenuAction(
                      child: const Text("Raw report data"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/raw_scout_report',
                            arguments: <String, dynamic>{
                              'longMatchKey': item.longMatchKey,
                              'team': item.team,
                            });
                      },
                    ),
                ],
                builder: (context, animation) {
                  return GestureDetector(
                      onTap: () {
                        if (animation.value == 0) {
                          Navigator.of(context)
                              .pushNamed("/team_lookup", arguments: {
                            'team': item.team,
                          });
                        }
                      },
                      child: Text(
                        item.team.toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ));
                },
              ),
              if (item.warnings.isNotEmpty)
                InkWell(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) => Dialog(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      5,
                                      5,
                                      0,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          icon: const Icon(Icons.close),
                                          tooltip: "Close",
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      0,
                                      20,
                                      20,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          "Issues with ${item.scout}'s data for ${GameMatchIdentity.fromLongKey(item.longMatchKey!).getShortLocalizedDescription()}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 5),
                                        ...(item.warnings
                                            .map((warning) => Text(
                                                  '• $warning',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge,
                                                ))
                                            .toList()),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      Icons.error,
                      color: Theme.of(context).colorScheme.warningText,
                      size: 24,
                    ),
                  ),
                )
            ],
          ),
          if (item.scout != null)
            Text(
              item.scout!,
              style: Theme.of(context).textTheme.labelSmall!.merge(
                    TextStyle(
                      color: alliance == Alliance.red
                          ? Theme.of(context).colorScheme.onRedAlliance
                          : Theme.of(context).colorScheme.onBlueAlliance,
                    ),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          // Column(
          //   crossAxisAlignment: alignment,
          //   children: item.warnings
          //       .map(
          //         (warning) => Row(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Icon(
          //               Icons.error,
          //               size: 20,
          //               color: Theme.of(context).colorScheme.warningText,
          //             ),
          //             Flexible(
          //               child: Padding(
          //                 padding: const EdgeInsets.fromLTRB(2, 2, 0, 0),
          //                 child: Text(
          //                   warning,
          //                   style: Theme.of(context)
          //                       .textTheme
          //                       .labelSmall!
          //                       .merge(TextStyle(
          //                           color: Theme.of(context)
          //                               .colorScheme
          //                               .warningText)),
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       )
          //       .toList(),
          // )
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

extension AllianceExtension on Alliance {
  static Alliance fromString(String string) {
    switch (string) {
      case "red":
        return Alliance.red;
      case "blue":
        return Alliance.blue;
      default:
        throw "Invalid alliance string";
    }
  }
}

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

class Matches extends StatefulWidget {
  const Matches(
      {super.key,
      required this.onRefresh,
      this.isScouted,
      required this.scrollController,
      this.filteredMatches,
      this.nextMatch,
      required this.nextMatchKey,
      this.isScoutingLead,
      this.scoutSchedule});

  final dynamic Function() onRefresh;
  final Map<String, String?>? isScouted;
  final ScrollController scrollController;
  final List<ScheduleMatch>? filteredMatches;

  final GameMatchIdentity? nextMatch;
  final GlobalKey<State<StatefulWidget>> nextMatchKey;
  final bool? isScoutingLead;
  final ScoutSchedule? scoutSchedule;

  @override
  State<Matches> createState() => _MatchesState();
}

class _MatchesState extends State<Matches> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: const Key('match-schedule-refresh'),
      onRefresh: () => widget.onRefresh(),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
            children: widget.filteredMatches!.map((match) {
          List<String?> scouted = [
            widget.isScouted!["${match.identity.toMediumKey()}_0"],
            widget.isScouted!["${match.identity.toMediumKey()}_1"],
            widget.isScouted!["${match.identity.toMediumKey()}_2"],
            widget.isScouted!["${match.identity.toMediumKey()}_3"],
            widget.isScouted!["${match.identity.toMediumKey()}_4"],
            widget.isScouted!["${match.identity.toMediumKey()}_5"],
          ];

          return Padding(
            key: match.identity.toMediumKey() == widget.nextMatch?.toMediumKey()
                ? widget.nextMatchKey
                : null,
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
                            padding: const EdgeInsets.fromLTRB(10, 13, 10, 13),
                            child: Text(
                              match.identity.getLocalizedDescription(
                                  includeTournament: false),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          if (!scouted.contains(null)) const ScoutedFlag(),
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
                            tooltip: "Match Predictor",
                          ),
                          // IconButton(
                          //   onPressed: () {
                          //     Navigator.of(context).pushNamed(
                          //       "/match_suggestions",
                          //       arguments: {
                          //         'teams': <String, int>{
                          //           'red1': match.teams[0],
                          //           'red2': match.teams[1],
                          //           'red3': match.teams[2],
                          //           'blue1': match.teams[3],
                          //           'blue2': match.teams[4],
                          //           'blue3': match.teams[5],
                          //         },
                          //         'matchIdentity': match.identity,
                          //         'matchType': match.identity.type,
                          //       },
                          //     );
                          //   },
                          //   icon: const Icon(Icons.assistant),
                          // ),
                        ],
                      ),
                      AllianceRow(
                        alliance: Alliance.red,
                        isScoutingLead: widget.isScoutingLead,
                        items: [
                          AllianceRowItem(
                            scouted: scouted[0] != null,
                            longMatchKey: "${match.identity.toMediumKey()}_0",
                            team: match.teams[0],
                            warnings: getWarnings(scouted, 0, []),
                          ),
                          AllianceRowItem(
                            scouted: scouted[1] != null,
                            longMatchKey: "${match.identity.toMediumKey()}_1",
                            team: match.teams[1],
                            warnings: getWarnings(scouted, 1, []),
                          ),
                          AllianceRowItem(
                            scouted: scouted[2] != null,
                            longMatchKey: "${match.identity.toMediumKey()}_2",
                            team: match.teams[2],
                            warnings: getWarnings(scouted, 2, []),
                          ),
                        ],
                      ),
                      AllianceRow(
                        alliance: Alliance.blue,
                        isScoutingLead: widget.isScoutingLead,
                        items: [
                          AllianceRowItem(
                            scouted: scouted[3] != null,
                            longMatchKey: "${match.identity.toMediumKey()}_3",
                            team: match.teams[3],
                            warnings: getWarnings(scouted, 3, []),
                          ),
                          AllianceRowItem(
                            scouted: scouted[4] != null,
                            longMatchKey: "${match.identity.toMediumKey()}_4",
                            team: match.teams[4],
                            warnings: getWarnings(scouted, 4, []),
                          ),
                          AllianceRowItem(
                            scouted: scouted[5] != null,
                            longMatchKey: "${match.identity.toMediumKey()}_5",
                            team: match.teams[5],
                            warnings: getWarnings(scouted, 5, []),
                          ),
                        ],
                      ),
                    ]),
              ),
            ),
          );
        }).toList()),
      ),
    );
  }

  List<String> getWarnings(
      List<String?> scouted, int scoutIndex, List<String> matchScheduleScouts) {
    return [
      if (scouted.any((scout) => scout != null) && scouted[scoutIndex] == null)
        "Must scan",
      if (scouted[scoutIndex] != null &&
          (matchScheduleScouts.isEmpty ||
              matchScheduleScouts[scoutIndex] != scouted[scoutIndex]))
        "By ${scouted[scoutIndex]}",
    ];
  }
}

class NoScheduleMessage extends StatelessWidget {
  const NoScheduleMessage(this.tournament, {super.key});

  final String tournament;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No matches for $tournament',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            "If it's on The Blue Alliance and the schedule has been posted, someone will need to add them to Lovat automatically. If it's a custom tournament, someone will need to manually add the matches.",
            style: Theme.of(context).textTheme.bodyMedium,
          )
        ].withSpaceBetween(height: 10),
      ),
    );
  }
}
