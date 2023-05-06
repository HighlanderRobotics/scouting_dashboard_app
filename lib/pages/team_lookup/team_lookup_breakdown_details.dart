import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class TeamLookupBreakdownDetailsPage extends StatelessWidget {
  const TeamLookupBreakdownDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    List<dynamic> rawMatchData = routeArgs['matches'];

    Map<GameMatchIdentity, String> matches = rawMatchData.asMap().map(
          (key, value) => MapEntry(
            GameMatchIdentity.fromLongKey(value['match']),
            value['value'],
          ),
        );
    BreakdownData breakdownData = routeArgs['breakdownData'];
    int team = routeArgs['team'];

    return Scaffold(
      appBar: AppBar(
        title: Text("$team - ${breakdownData.localizedName}"),
      ),
      body: ScrollablePageBody(children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Matches"),
                  ...(matches
                      .map((match, value) => MapEntry(
                          match,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                match.getLocalizedDescription(
                                  includeTournament: false,
                                ),
                              ),
                              Text(
                                breakdownData.segments
                                    .firstWhere((e) => e.path == value)
                                    .localizedNameSingular,
                              ),
                            ],
                          )))
                      .values
                      .toList()),
                  if (matches.isEmpty)
                    const Text(
                      "No data in any matches",
                      textAlign: TextAlign.center,
                    ),
                ]),
          ),
        )
      ]),
    );
  }
}
