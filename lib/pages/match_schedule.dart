import 'package:chips_input/chips_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/raw_scout_report.dart';
import 'package:scouting_dashboard_app/pages/team_per_match.dart';
import 'package:scouting_dashboard_app/reusable/color_combination.dart';
import 'package:scouting_dashboard_app/reusable/color_combination.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';
import 'package:scouting_dashboard_app/reusable/models/user_profile.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:skeletons/skeletons.dart';

import '../reusable/navigation_drawer.dart';

class MatchSchedulePage extends StatefulWidget {
  const MatchSchedulePage({super.key});

  @override
  State<MatchSchedulePage> createState() => _MatchSchedulePageState();
}

class _MatchSchedulePageState extends State<MatchSchedulePage> {
  List<Team> _teamsFilter = [];
  CompletionFilter completionFilter = CompletionFilter.any;

  GameMatchIdentity? nextMatch;

  List<MatchScheduleMatch>? matches;

  String? initialError;
  String? noScheduleTournament;

  List<Team>? teamsInTournament;

  bool isDataFetched = false;
  bool? isScoutingLead;
  Tournament? currentTournament;
  bool showProgressIndicator = false;

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

  Future<void> fetchData({bool indicator = true}) async {
    try {
      if (indicator && currentTournament != null) {
        setState(() {
          showProgressIndicator = true;
        });
      }

      final tournament = await Tournament.getCurrent();

      setState(() {
        currentTournament = tournament;
      });

      if (tournament == null) {
        setState(() {
          noScheduleTournament = "No tournament selected";
          isDataFetched = true;
        });
        return;
      } // TODO: Make this message

      final matches = await lovatAPI.getMatches(
        tournament.key,
        isScouted: completionFilter == CompletionFilter.any
            ? null
            : completionFilter == CompletionFilter.finished,
        teamNumbers: _teamsFilter.isEmpty
            ? null
            : _teamsFilter.map((e) => e.number).toList(),
      );

      GameMatchIdentity? nextMatch = this.nextMatch;
      if (_teamsFilter.isEmpty && completionFilter == CompletionFilter.any) {
        final MatchScheduleMatch? lastScouted = matches.cast().lastWhere(
              (match) => match.isScouted,
              orElse: () => null,
            );

        if (lastScouted == null) {
          nextMatch = matches.first.identity;
        } else {
          final index = matches.indexOf(lastScouted);

          if (index == matches.length - 1) {
            nextMatch = null;
          } else {
            nextMatch = matches[index + 1].identity;
          }
        }
      }

      setState(() {
        this.matches = matches;
        this.nextMatch = nextMatch;
        isDataFetched = true;
      });
    } on LovatAPIException catch (e) {
      if (e.message == "Tournament not found") {
        setState(() {
          noScheduleTournament =
              currentTournament?.localized ?? "No tournament";
          isDataFetched = true;
        });
      } else {
        setState(() {
          initialError = e.message;
        });
      }
    } catch (e) {
      setState(() {
        initialError = "An unknown error occurred";
      });
    } finally {
      setState(() {
        showProgressIndicator = false;
      });
    }
  }

  Future<void> fetchTeamsInTournament() async {
    try {
      final tournament = await Tournament.getCurrent();

      final teams = await tournament?.getTeams();

      setState(() {
        teamsInTournament = teams;
      });
    } on LovatAPIException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error fetching teams: ${e.message}",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
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
                          } else {
                            setState(() {
                              completionFilter = CompletionFilter.upcoming;
                            });
                          }

                          fetchData();
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
                          } else {
                            setState(() {
                              completionFilter = CompletionFilter.finished;
                            });
                          }

                          fetchData();
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
              SizedBox(
                height: 4,
                child: showProgressIndicator
                    ? const LinearProgressIndicator()
                    : Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
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
                : (matches == null)
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
                          onRefresh: () => fetchData(indicator: false),
                          scrollController: scrollController,
                          matches: matches,
                          nextMatch: nextMatch,
                          nextMatchKey: nextMatchKey,
                          isScoutingLead: isScoutingLead,
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

  ChipsInput<Team> teamsInput() {
    return ChipsInput(
      chipBuilder: ((context, state, data) {
        return Transform(
          transform: Matrix4.translationValues(0, -2, 0),
          child: InputChip(
            label: Text(data.number.toString()),
            onDeleted: () => state.deleteChip(data),
            backgroundColor: Theme.of(context).colorScheme.background,
            labelStyle: Theme.of(context).textTheme.labelLarge!.merge(TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
            deleteIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      }),
      findSuggestions: ((query) {
        if (query.isEmpty) {
          return <Team>[];
        }

        final parsedQuery = int.tryParse(query);

        if (teamsInTournament == null && parsedQuery != null) {
          return <Team>[
            Team(
              number: parsedQuery,
              name: "",
            ),
          ];
        }

        if (teamsInTournament != null) {
          return teamsInTournament!
              .where((team) =>
                  team.name.toLowerCase().contains(query.toLowerCase()) ||
                  team.number.toString().contains(query))
              .toList();
        }

        return <Team>[];
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

        fetchData();
      },
      suggestionBuilder: (context, data) {
        return ListTile(
            title: Text(data.name == ""
                ? data.number.toString()
                : "${data.number} - ${data.name}"));
      },
      maxChips: 3,
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
    required this.matchIdentity,
    required this.longMatchKey,
    required this.teamInfo,
  });

  final GameMatchIdentity matchIdentity;
  final String longMatchKey;
  final MatchScheduleTeamInfo teamInfo;

  bool get isScouted =>
      teamInfo.scouters.where((s) => s.isScouted == true).isNotEmpty;
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
          'teams': items.map((e) => e.teamInfo.teamNumber).toList(),
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
                        'team': item.teamInfo.teamNumber,
                      });
                    },
                  ),
                  if (item.isScouted && isScoutingLead == true)
                    CupertinoContextMenuAction(
                      child: const Text("View report data"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushWidget(RawScoutReportsPage(
                          longMatchKey: item.longMatchKey,
                          teamNumber: item.teamInfo.teamNumber,
                        ));
                      },
                    ),
                ],
                builder: (context, animation) {
                  return GestureDetector(
                      onTap: () {
                        if (animation.value == 0) {
                          Navigator.of(context)
                              .pushNamed("/team_lookup", arguments: {
                            'team': item.teamInfo.teamNumber,
                          });
                        }
                      },
                      child: Text(
                        item.teamInfo.teamNumber.toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ));
                },
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...(item.teamInfo.scouters
                  .map((scouterInfo) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            scouterInfo.isScouted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: alliance == Alliance.red
                                ? Theme.of(context).colorScheme.onRedAlliance
                                : Theme.of(context).colorScheme.onBlueAlliance,
                          ),
                          Text(
                            scouterInfo.name,
                            style:
                                Theme.of(context).textTheme.labelSmall!.merge(
                                      TextStyle(
                                        color: alliance == Alliance.red
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onRedAlliance
                                            : Theme.of(context)
                                                .colorScheme
                                                .onBlueAlliance,
                                      ),
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ].withSpaceBetween(width: 2),
                      ))
                  .toList()),
              if (item.teamInfo.externalReportCount != 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    "${item.teamInfo.externalReportCount} external\nreport${item.teamInfo.externalReportCount == 1 ? "" : "s"}",
                    style: Theme.of(context).textTheme.labelSmall!.merge(
                          TextStyle(
                            color: alliance == Alliance.red
                                ? Theme.of(context).colorScheme.onRedAlliance
                                : Theme.of(context).colorScheme.onBlueAlliance,
                            height: 1.1,
                          ),
                        ),
                  ),
                ),
            ],
          ),
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

  ColorCombination get colorCombination {
    switch (this) {
      case Alliance.red:
        return ColorCombination.red;
      case Alliance.blue:
        return ColorCombination.blue;
    }
  }

  ColorCombination get emphasisColorCombination {
    switch (this) {
      case Alliance.red:
        return ColorCombination.redEmphasis;
      case Alliance.blue:
        return ColorCombination.blueEmphasis;
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
  const Matches({
    super.key,
    required this.onRefresh,
    this.isScouted,
    required this.scrollController,
    this.matches,
    this.nextMatch,
    required this.nextMatchKey,
    this.isScoutingLead,
  });

  final dynamic Function() onRefresh;
  final Map<String, String?>? isScouted;
  final ScrollController scrollController;
  final List<MatchScheduleMatch>? matches;

  final GameMatchIdentity? nextMatch;
  final GlobalKey<State<StatefulWidget>> nextMatchKey;
  final bool? isScoutingLead;

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
            children: widget.matches!.map((match) {
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
                          if (match.isScouted) const ScoutedFlag(),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                "/match_predictor",
                                arguments: {
                                  'red1': match.red1.teamNumber.toString(),
                                  'red2': match.red2.teamNumber.toString(),
                                  'red3': match.red3.teamNumber.toString(),
                                  'blue1': match.blue1.teamNumber.toString(),
                                  'blue2': match.blue2.teamNumber.toString(),
                                  'blue3': match.blue3.teamNumber.toString(),
                                },
                              );
                            },
                            icon: const Icon(Icons.psychology),
                            tooltip: "Match Predictor",
                          ),
                        ],
                      ),
                      AllianceRow(
                        alliance: Alliance.red,
                        isScoutingLead: widget.isScoutingLead,
                        items: [
                          AllianceRowItem(
                            matchIdentity: match.identity,
                            longMatchKey: "${match.identity.toMediumKey()}_0",
                            teamInfo: match.red1,
                          ),
                          AllianceRowItem(
                            matchIdentity: match.identity,
                            longMatchKey: "${match.identity.toMediumKey()}_1",
                            teamInfo: match.red2,
                          ),
                          AllianceRowItem(
                            matchIdentity: match.identity,
                            longMatchKey: "${match.identity.toMediumKey()}_2",
                            teamInfo: match.red3,
                          ),
                        ],
                      ),
                      AllianceRow(
                        alliance: Alliance.blue,
                        isScoutingLead: widget.isScoutingLead,
                        items: [
                          AllianceRowItem(
                            matchIdentity: match.identity,
                            longMatchKey: "${match.identity.toMediumKey()}_3",
                            teamInfo: match.blue1,
                          ),
                          AllianceRowItem(
                            matchIdentity: match.identity,
                            longMatchKey: "${match.identity.toMediumKey()}_4",
                            teamInfo: match.blue2,
                          ),
                          AllianceRowItem(
                            matchIdentity: match.identity,
                            longMatchKey: "${match.identity.toMediumKey()}_5",
                            teamInfo: match.blue3,
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
            'No schedule found for $tournament',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            "The Lovat team may have deleted the tournament in the process of removing test data. Open settings to select a tournament that exists.",
            style: Theme.of(context).textTheme.bodyMedium,
          )
        ].withSpaceBetween(height: 10),
      ),
    );
  }
}
