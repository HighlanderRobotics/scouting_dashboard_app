import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/scanner_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:soundpool/soundpool.dart';

class ScanQRCodesPage extends StatefulWidget {
  const ScanQRCodesPage({super.key});

  @override
  State<ScanQRCodesPage> createState() => _ScanQRCodesPageState();
}

class QRDataCollection {
  QRDataCollection({
    required this.data,
    this.totalPageCount,
  });

  List<Map<String, dynamic>> data;
  int? totalPageCount;
}

class _ScanQRCodesPageState extends State<ScanQRCodesPage> {
  List<QRDataCollection> reportData = [
    QRDataCollection(data: []),
    QRDataCollection(data: []),
    QRDataCollection(data: []),
    QRDataCollection(data: []),
    QRDataCollection(data: []),
    QRDataCollection(data: []),
  ];

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
      drawer: const GlobalNavigationDrawer(),
      body: ScannerBody(
        onDetect: (barcodeCapture) {
          Barcode? code;
          if (barcodeCapture.barcodes.isEmpty) {
            code = null;
          } else {
            code = barcodeCapture.barcodes.first;
          }

          if (code == null || code.rawValue == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Something went wrong.")));
          }

          print(code!.rawValue);

          Map<String, dynamic> parsedData = jsonDecode(code.rawValue!);

          if (reportData[parsedData['scouterId']].data.any((datum) =>
              datum['uuid'] == parsedData['uuid'] &&
              datum['currentPage'] == parsedData['currentPage'])) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Code already scaned"),
              behavior: SnackBarBehavior.floating,
            ));

            (() async {
              Soundpool pool = Soundpool.fromOptions(
                options:
                    const SoundpoolOptions(streamType: StreamType.notification),
              );

              int soundId = await rootBundle
                  .load("assets/sounds/fail.mp3")
                  .then((ByteData soundData) {
                return pool.load(soundData);
              });

              HapticFeedback.heavyImpact();

              int streamId = await pool.play(soundId);
            })();

            return;
          }

          setState(() {
            reportData[parsedData['scouterId']].data.add(parsedData);
            reportData[parsedData['scouterId']].totalPageCount =
                parsedData['totalPages'];
          });

          if (reportData[parsedData['scouterId']].data.length !=
              reportData[parsedData['scouterId']].totalPageCount) {
            (() async {
              Soundpool pool = Soundpool.fromOptions(
                options:
                    const SoundpoolOptions(streamType: StreamType.notification),
              );

              int soundId = await rootBundle
                  .load("assets/sounds/success.mp3")
                  .then((ByteData soundData) {
                return pool.load(soundData);
              });

              HapticFeedback.heavyImpact();

              int streamId = await pool.play(soundId);
            })();
          } else {
            (() async {
              Soundpool pool = Soundpool.fromOptions(
                options:
                    const SoundpoolOptions(streamType: StreamType.notification),
              );

              int soundId = await rootBundle
                  .load("assets/sounds/great_success.mp3")
                  .then((ByteData soundData) {
                return pool.load(soundData);
              });

              HapticFeedback.heavyImpact();

              int streamId = await pool.play(soundId);

              reportData[parsedData['scouterId']].data.sort(((a, b) =>
                  (a['currentPage'] as int)
                      .compareTo(b['currentPage'] as int)));

              String fullJSON = reportData[parsedData['scouterId']]
                  .data
                  .map((e) => e['data'])
                  .join();

              Map<String, dynamic> parsedFullJSON = jsonDecode(fullJSON);

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    "Uploading ${parsedFullJSON['scouterName']}'s data on ${parsedFullJSON['teamNumber']}"),
                behavior: SnackBarBehavior.floating,
              ));

              await http.post(
                  Uri.http(
                    (await getServerAuthority())!,
                    "/API/manager/addScoutReport",
                  ),
                  body: fullJSON,
                  headers: <String, String>{
                    'Content-Type': 'application/json',
                  });

              ScaffoldMessenger.of(context)
                  .hideCurrentSnackBar(reason: SnackBarClosedReason.remove);

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    "Uploaded ${parsedFullJSON['scouterName']}'s data on ${parsedFullJSON['teamNumber']}"),
                behavior: SnackBarBehavior.floating,
              ));
            })();
          }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(6, (index) => index)
                    .map(
                      (i) => ScoutStatus(
                        name: nextMatchStatus[i] ?? nextMatchPlannedScouts[i],
                        scanned: nextMatchStatus[i] != null,
                        dataCollection: reportData[i],
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
    required this.dataCollection,
  }) : super(key: key);

  final bool scanned;
  final String name;
  final QRDataCollection dataCollection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(children: [
        scanned || dataCollection.data.length == dataCollection.totalPageCount
            ? const Icon(Icons.check_box)
            : Text(
                "${dataCollection.data.length}/${dataCollection.totalPageCount ?? '--'}"),
        const SizedBox(width: 5),
        Text(name),
      ]),
    );
  }
}
