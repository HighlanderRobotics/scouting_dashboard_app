import 'dart:convert';

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

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
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
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        child: FutureBuilder(future: (() async {
          final TournamentSchedule tournamentSchedule =
              await TournamentSchedule.fromServer(
            (await getServerAuthority())!,
            (await SharedPreferences.getInstance()).getString('tournament')!,
          );

          return {
            'tournamentSchedule': tournamentSchedule,
            'scoutSchedule': await getScoutSchedule(),
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

          debugPrint(snapshot.toString());

          return ListView.builder(
            addAutomaticKeepAlives: true,
            // itemExtent: 190,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: FutureBuilder(
                  future: (() async {
                    List<Map<String, dynamic>> scoutedResponse =
                        (jsonDecode(utf8.decode((await http.get(
                      Uri.http((await getServerAuthority())!,
                          '/API/manager/isScouted', {
                        'matchKey': tournamentSchedule.matches[index].identity
                            .toMediumKey(),
                        'tournamentKey': (await SharedPreferences.getInstance())
                            .getString('tournament'),
                      }),
                    ))
                                .bodyBytes)) as List<dynamic>)
                            .cast();

                    List<String?> scouts = [
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                    ];

                    for (var i = 0; i < 6; i++) {
                      scouts[i] = scoutedResponse.firstWhere((element) =>
                          int.parse((element['key'] as String).split("_")[2]) ==
                          i)['name'];
                    }

                    return {
                      'scouted': scouts,
                    };
                  })(),
                  builder: (context, scoutersSnapshot) {
                    if (scoutersSnapshot.connectionState !=
                        ConnectionState.done) {
                      return const SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          height: 170,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      );
                    }

                    final List<String?> scouted =
                        scoutersSnapshot.data!['scouted']!.cast();
                    final match = tournamentSchedule.matches[index];

                    return ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
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
                                    const ScoutedFlag()
                                ],
                              ),
                              AllianceRow(
                                alliance: Alliance.red,
                                items: [
                                  AllianceRowItem(
                                    team: match.teams[0],
                                    scout: scoutSchedule.getScoutsForMatch(
                                        match.ordinalNumber)[0],
                                    warnings: [
                                      if (scouted
                                              .any((scout) => scout != null) &&
                                          scouted[0] == null)
                                        "Must scan"
                                    ],
                                  ),
                                  AllianceRowItem(
                                    team: match.teams[1],
                                    scout: scoutSchedule.getScoutsForMatch(
                                        match.ordinalNumber)[1],
                                    warnings: [
                                      if (scouted.any((element) => false) &&
                                          scouted[1] == null)
                                        "Must scan"
                                    ],
                                  ),
                                  AllianceRowItem(
                                    team: match.teams[2],
                                    scout: scoutSchedule.getScoutsForMatch(
                                        match.ordinalNumber)[2],
                                    warnings: [
                                      if (scouted.any((element) => false) &&
                                          scouted[2] == null)
                                        "Must scan"
                                    ],
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
                                    warnings: [
                                      if (scouted.any((element) => false) &&
                                          scouted[3] == null)
                                        "Must scan"
                                    ],
                                  ),
                                  AllianceRowItem(
                                    team: match.teams[4],
                                    scout: scoutSchedule.getScoutsForMatch(
                                        match.ordinalNumber)[4],
                                    warnings: [
                                      if (scouted.any((element) => false) &&
                                          scouted[4] == null)
                                        "Must scan"
                                    ],
                                  ),
                                  AllianceRowItem(
                                    team: match.teams[5],
                                    scout: scoutSchedule.getScoutsForMatch(
                                        match.ordinalNumber)[5],
                                    warnings: [
                                      if (scouted.any((element) => false) &&
                                          scouted[5] == null)
                                        "Must scan"
                                    ],
                                  ),
                                ],
                              ),
                            ]),
                      ),
                    );
                  },
                ),
              );
            },
            itemCount: tournamentSchedule.matches.length,
          );
        }),
      ),
      drawer: const NavigationDrawer(),
    );
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
          Text(
            item.team.toString(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            item.scout,
            style: Theme.of(context).textTheme.labelSmall!.merge(
                  TextStyle(
                      color: alliance == Alliance.red
                          ? onRedAlliance
                          : onBlueAlliance),
                ),
            textAlign: {
              CrossAxisAlignment.start: TextAlign.start,
              CrossAxisAlignment.center: TextAlign.center,
              CrossAxisAlignment.end: TextAlign.end,
            }[alignment],
          ),
          Column(
            children: item.warnings
                .map(
                  (warning) => Row(children: [
                    Icon(
                      Icons.error,
                      size: 20,
                      color: warningText,
                    ),
                    const SizedBox(width: 1),
                    Text(
                      warning,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .merge(TextStyle(color: warningText)),
                    ),
                  ]),
                )
                .toList(),
          )
        ],
      ),
    );
  }
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
