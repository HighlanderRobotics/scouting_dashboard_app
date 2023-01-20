import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/scanner_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ScanQRCodesPage extends StatefulWidget {
  const ScanQRCodesPage({super.key});

  @override
  State<ScanQRCodesPage> createState() => _ScanQRCodesPageState();
}

class _ScanQRCodesPageState extends State<ScanQRCodesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Codes"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const NavigationDrawer(),
      body: ScannerBody(
        onDetect: (code, args) {
          Map<String, dynamic> scoutReport = jsonDecode(code.rawValue!);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Scanned ${scoutReport['scouterName']}'s data on ${scoutReport['teamNumber']}",
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

          (() async {
            await http.post(
              Uri.http(
                (await getServerAuthority())!,
                '/API/manager/addScoutReport',
              ),
              body: code.rawValue!,
              headers: <String, String>{
                'Content-Type': 'application/json',
              },
            );

            ScaffoldMessenger.of(context)
                .removeCurrentSnackBar(reason: SnackBarClosedReason.dismiss);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Uploaded ${scoutReport['scouterName']}'s data on ${scoutReport['teamNumber']}",
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );

            setState(() {});
          })();
        },
        childBelow: FutureBuilder(future: (() async {
          Map<String, String?> isScoutedAll = await getScoutedStatuses();
          TournamentSchedule tournamentSchedule =
              await TournamentSchedule.fromServer(
            (await getServerAuthority())!,
            (await SharedPreferences.getInstance()).getString(("tournament"))!,
          );
          ScoutSchedule scoutSchedule = await getScoutSchedule();

          late final ScheduleMatch nextUnscoutedMatch;
          late final List<String?> nextUnscoutedMatchStatus;
          late final List<String> nextUnscoutedMatchPlannedScouts;

          for (var match in tournamentSchedule.matches) {
            var currentMatchStatus = [
              "${match.identity.toMediumKey()}_0",
              "${match.identity.toMediumKey()}_1",
              "${match.identity.toMediumKey()}_2",
              "${match.identity.toMediumKey()}_3",
              "${match.identity.toMediumKey()}_4",
              "${match.identity.toMediumKey()}_5",
            ];

            if (currentMatchStatus
                .any((element) => isScoutedAll[element] == null)) {
              nextUnscoutedMatch = match;
              nextUnscoutedMatchStatus =
                  currentMatchStatus.map((e) => isScoutedAll[e]).toList();
              nextUnscoutedMatchPlannedScouts = scoutSchedule.getScoutsForMatch(
                match.ordinalNumber,
              );

              return {
                'nextMatch': nextUnscoutedMatch,
                'nextMatchStatus': nextUnscoutedMatchStatus,
                'nextMatchPlannedScouts': nextUnscoutedMatchPlannedScouts,
              };
            }
          }
        })(), builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          ScheduleMatch nextMatch =
              snapshot.data!['nextMatch'] as ScheduleMatch;
          List<String?> nextMatchStatus =
              snapshot.data!['nextMatchStatus'] as List<String?>;
          List<String> nextMatchPlannedScouts =
              snapshot.data!['nextMatchPlannedScouts'] as List<String>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  nextMatch.identity
                      .getLocalizedDescription(includeTournament: false),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Column(
                children: List.generate(6, (index) => index)
                    .map(
                      (i) => ScoutStatus(
                        name: nextMatchStatus[i] ?? nextMatchPlannedScouts[i],
                        scanned: nextMatchStatus[i] != null,
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class ScoutStatus extends StatelessWidget {
  const ScoutStatus({
    Key? key,
    required this.name,
    required this.scanned,
  }) : super(key: key);

  final bool scanned;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        Icon(scanned ? Icons.check_box : Icons.check_box_outline_blank),
        const SizedBox(width: 5),
        Text(name),
      ]),
    );
  }
}
