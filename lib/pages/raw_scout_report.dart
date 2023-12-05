import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';

class RawScoutReportPage extends StatefulWidget {
  const RawScoutReportPage({super.key});

  @override
  State<RawScoutReportPage> createState() => _RawScoutReportPageState();
}

class _RawScoutReportPageState extends State<RawScoutReportPage> {
  @override
  Widget build(BuildContext context) {
    int team = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['team'];

    String longMatchKey = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['longMatchKey'];

    final GameMatchIdentity matchIdentity =
        GameMatchIdentity.fromLongKey(longMatchKey);

    return FutureBuilder<Map<String, dynamic>>(
      future: (() async {
        final authority = (await getServerAuthority())!;

        final response =
            await http.get(Uri.http(authority, '/API/manager/getScoutReport', {
          'matchKey': longMatchKey,
        }));

        return jsonDecode(response.body)[0] as Map<String, dynamic>;
      })(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                  "Scout Report in ${matchIdentity.getShortLocalizedDescription()}"),
            ),
            body: snapshot.hasError
                ? ScrollablePageBody(children: [
                    Text("Encountered an error: ${snapshot.error}"),
                  ])
                : const PageBody(
                    child: Column(
                    children: [
                      LinearProgressIndicator(),
                    ],
                  )),
          );
        }

        String uuid = snapshot.data!['uuid'];

        String scouterName = snapshot.data!['scouterName'];
        String notes = snapshot.data!['notes'];

        Map<String, dynamic> scoutReport =
            jsonDecode(snapshot.data!['scoutReport']);

        List<dynamic> rawEvents = scoutReport['events'];
        RobotRole robotRole = RobotRole.values[scoutReport['robotRole']];
        ChallengeResult autoChallengeResult =
            ChallengeResult.values[scoutReport['autoChallengeResult']];
        ChallengeResult teleopChallengeResult =
            ChallengeResult.values[scoutReport['challengeResult']];
        Penalty penaltyCard = Penalty.values[scoutReport['penaltyCard']];
        int? links = scoutReport['links'];
        DriverAbility driverAbility =
            DriverAbility.values[scoutReport['driverAbility']];

        List<ScoutReportEvent> timeline = rawEvents
            .map((e) => ScoutReportEvent.fromList(e.cast<int>()))
            .toList();

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                "Scout Report: $team in ${matchIdentity.getShortLocalizedDescription()}",
              ),
              bottom: const TabBar(
                labelPadding: EdgeInsets.symmetric(vertical: 11),
                tabs: [
                  Text("Fields"),
                  Text("Timeline"),
                  Text("Raw"),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text("Delete data?"),
                              content: Text(
                                  "You're about to delete all of the data $scouterName collected on $team during ${matchIdentity.getLocalizedDescription(includeTournament: false).toLowerCase()}. Are you sure you want to continue?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Cancel"),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text("Deleting..."),
                                      behavior: SnackBarBehavior.floating,
                                    ));

                                    try {
                                      final authority =
                                          (await getServerAuthority())!;

                                      final response = await http.get(Uri.http(
                                          authority,
                                          '/API/manager/deleteData', {
                                        'uuid': uuid,
                                      }));

                                      if (response.statusCode != 200) {
                                        throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
                                      }
                                    } catch (error) {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                          "Error deleting data: $error",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onErrorContainer),
                                        ),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .errorContainer,
                                        behavior: SnackBarBehavior.floating,
                                      ));

                                      return;
                                    }
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content:
                                          Text("Successfully deleted data"),
                                      behavior: SnackBarBehavior.floating,
                                    ));

                                    Navigator.of(context).pop();
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateColor.resolveWith(
                                      (states) =>
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    foregroundColor:
                                        MaterialStateColor.resolveWith(
                                      (states) =>
                                          Theme.of(context).colorScheme.onError,
                                    ),
                                  ),
                                  child: const Text("Delete it"),
                                ),
                              ],
                            ));
                  },
                  icon: const Icon(Icons.delete),
                  tooltip: "Delete data",
                ),
              ],
            ),
            body: TabBarView(children: [
              fieldsTab(
                scouterName,
                robotRole,
                autoChallengeResult,
                teleopChallengeResult,
                driverAbility,
                penaltyCard,
                links,
                notes,
              ),
              timelineTab(timeline, context),
              rawTab(snapshot),
            ]),
          ),
        );
      },
    );
  }

  SafeArea rawTab(AsyncSnapshot<Map<String, dynamic>> snapshot) {
    return SafeArea(
      child: SyntaxView(
        code: const JsonEncoder.withIndent('    ').convert(<String, dynamic>{
          ...snapshot.data!,
          'scoutReport': jsonDecode(snapshot.data!['scoutReport']),
        }),
        syntax: Syntax.JAVASCRIPT,
        syntaxTheme: SyntaxTheme.vscodeDark(),
        expanded: true,
      ),
    );
  }

  ScrollablePageBody timelineTab(
      List<ScoutReportEvent> timeline, BuildContext context) {
    return ScrollablePageBody(
        children: timeline
            .map((event) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        minutesAndSeconds(event.timestamp),
                        textAlign: TextAlign.end,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .merge(TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            )),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        event.localizedDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ].withSpaceBetween(width: 5),
                ))
            .toList()
            .withSpaceBetween(height: 10));
  }

  ScrollablePageBody fieldsTab(
    String scouterName,
    RobotRole robotRole,
    ChallengeResult autoChallengeResult,
    ChallengeResult teleopChallengeResult,
    DriverAbility driverAbility,
    Penalty penaltyCard,
    int? links,
    String notes,
  ) {
    return ScrollablePageBody(
        children: [
      field("Scouter", scouterName),
      field(
        "Role",
        robotRole.name,
        valueLeading: Icon(robotRole.littleEmblem),
      ),
      field("Auto Charge", autoChallengeResult.localizedDescription),
      field("Teleop Charge", teleopChallengeResult.localizedDescription),
      field("Driver Ability",
          "${driverAbility.localizedDescription} (${driverAbility.index + 1}/${DriverAbility.values.length})"),
      field("Penalty Cards", penaltyCard.localizedDescription),
      field("Links", links == null ? '--' : links.toString()),
      field("Notes", notes.isEmpty ? "--" : notes)
    ].withSpaceBetween(height: 10));
  }

  Widget field(String title, String value, {Widget? valueLeading}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Row(
            children: [
              if (valueLeading != null) valueLeading,
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ].withSpaceBetween(width: 2),
          ),
        ],
      );
}

enum ChallengeResult {
  none,
  docked,
  engaged,
  failed,
  inCommunity,
}

extension ChallengeResultExtension on ChallengeResult {
  String get localizedDescription {
    switch (this) {
      case ChallengeResult.none:
        return "None";
      case ChallengeResult.docked:
        return "Docked";
      case ChallengeResult.engaged:
        return "Engaged";
      case ChallengeResult.failed:
        return "Failed";
      case ChallengeResult.inCommunity:
        return "In community";
      default:
        return "Unknown";
    }
  }
}

enum DriverAbility {
  terrible,
  poor,
  average,
  good,
  great,
}

extension DriverAbilityExtension on DriverAbility {
  String get localizedDescription {
    switch (this) {
      case DriverAbility.terrible:
        return "Terrible";
      case DriverAbility.poor:
        return "Poor";
      case DriverAbility.average:
        return "Average";
      case DriverAbility.good:
        return "Good";
      case DriverAbility.great:
        return "Great";
      default:
        return "Unknown";
    }
  }
}

class ScoutReportEvent {
  const ScoutReportEvent({
    required this.timestamp,
    required this.action,
    required this.position,
  });

  final Duration timestamp;
  final ScoutReportEventAction action;
  final ScoutReportEventPosition position;

  factory ScoutReportEvent.fromList(List<int> list) => ScoutReportEvent(
        timestamp: Duration(seconds: list[0]),
        action: ScoutReportEventAction.values[list[1]],
        position: ScoutReportEventPosition.values[list[2]],
      );

  String get localizedDescription {
    String output = action.localizedPastTense;

    if (position != ScoutReportEventPosition.none) {
      output += " at ${position.localizedDescription}";
    }

    return output;
  }
}

enum ScoutReportEventAction {
  pickUpCube,
  pickUpCone,
  placeObject,
  dropObject,
  deliverToCommunity,
  startDefense,
  endDefense,
  crossCommunityLine,
  startMatch,
}

extension ScoutReportEventActionExtension on ScoutReportEventAction {
  String get localizedPastTense {
    switch (this) {
      case ScoutReportEventAction.pickUpCube:
        return "Picked up a cube";
      case ScoutReportEventAction.pickUpCone:
        return "Picked up a cone";
      case ScoutReportEventAction.placeObject:
        return "Placed an object";
      case ScoutReportEventAction.dropObject:
        return "Dropped an object";
      case ScoutReportEventAction.deliverToCommunity:
        return "Delivered an object to the community";
      case ScoutReportEventAction.startDefense:
        return "Started actively defending";
      case ScoutReportEventAction.endDefense:
        return "Finished actively defending";
      case ScoutReportEventAction.crossCommunityLine:
        return "Crossed the community border";
      case ScoutReportEventAction.startMatch:
        return "Began the match";
    }
  }
}

enum ScoutReportEventPosition {
  none,
  grid1,
  grid2,
  grid3,
  grid4,
  grid5,
  grid6,
  grid7,
  grid8,
  grid9,
  cableProtector,
  chargeStation,
  clearsideCommunityBorder,
  farClearsidePreplacedPiece,
  centralClearsidePreplacedPiece,
  centralBumpsidePreplacedPiece,
  farBumpsidePreplacedPiece,
  communityCenter3,
  communityCenter2,
  communityCenter1,
}

extension ScoutReportEventPositionExtension on ScoutReportEventPosition {
  String get localizedDescription {
    switch (this) {
      case ScoutReportEventPosition.none:
        return "nowhere";
      case ScoutReportEventPosition.grid1:
        return "a bump-side L1 node";
      case ScoutReportEventPosition.grid2:
        return "a middle L1 node";
      case ScoutReportEventPosition.grid3:
        return "a clear-side L1 node";
      case ScoutReportEventPosition.grid4:
        return "a bump-side L2 node";
      case ScoutReportEventPosition.grid5:
        return "a middle L2 node";
      case ScoutReportEventPosition.grid6:
        return "a clear-side L2 node";
      case ScoutReportEventPosition.grid7:
        return "a bump-side L3 node";
      case ScoutReportEventPosition.grid8:
        return "a middle L3 node";
      case ScoutReportEventPosition.grid9:
        return "a clear-side L3 node";
      case ScoutReportEventPosition.cableProtector:
        return "the cable protector";
      case ScoutReportEventPosition.chargeStation:
        return "the charge station";
      case ScoutReportEventPosition.clearsideCommunityBorder:
        return "the clear-side community border";
      case ScoutReportEventPosition.farClearsidePreplacedPiece:
        return "the far clear-side pre-placed game piece slot";
      case ScoutReportEventPosition.centralClearsidePreplacedPiece:
        return "the central clear-side pre-placed game piece slot";
      case ScoutReportEventPosition.centralBumpsidePreplacedPiece:
        return "the central bump-side pre-placed game piece slot";
      case ScoutReportEventPosition.farBumpsidePreplacedPiece:
        return "the far bump-side pre-placed game piece slot";
      case ScoutReportEventPosition.communityCenter3:
        return "the clear-side center of the community";
      case ScoutReportEventPosition.communityCenter2:
        return "the center of the community ajacent to the charge station";
      case ScoutReportEventPosition.communityCenter1:
        return "the bump-side center of the community";
    }
  }
}
