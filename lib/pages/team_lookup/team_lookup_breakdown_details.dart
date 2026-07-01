import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/pages/raw_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_breakdown_details.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';

class BreakdownDetailsPage extends StatelessWidget {
  const BreakdownDetailsPage({
    super.key,
    required this.team,
    required this.breakdownIdentity,
  });

  final int team;
  final BreakdownData breakdownIdentity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$team - ${breakdownIdentity.localizedName}"),
      ),
      body: StaleRefreshBuilder(
        query: lovatAPI.breakdownDetailsQuery(team, breakdownIdentity.path),
        builder: (context, result) {
          final data = result.data;
          if (result.hasError && !result.hasData) {
            return FriendlyErrorView.result(result);
          }

          if (data == null) {
            return const Column(children: [LinearProgressIndicator()]);
          }

          return Stack(
            children: [
              ScrollablePageBody(
                  children: data.matchesWithSegments
                      .map((segment) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionTitle(segment.segmentName),
                            const SizedBox(height: 8),
                            ...segment.matches
                                .map((match) {
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(match.matchIdentity
                                          .getLocalizedDescription(
                                              abbreviateName: true)),
                                      Text(match.sourceDescription),
                                    ],
                                  );
                                })
                                .toList()
                                .withSpaceBetween(height: 7)
                          ],
                        );
                      })
                      .toList()
                      .withWidgetBetween(const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Divider(height: 1),
                      ))),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: StaleRefreshIndicator.result(result),
              ),
            ],
          );
        },
      ),
    );
  }
}
