import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/pages/raw_scout_report.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_breakdown_details.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';

class BreakdownDetailsPage extends StatefulWidget {
  const BreakdownDetailsPage({
    super.key,
    required this.team,
    required this.breakdownIdentity,
  });

  final int team;
  final BreakdownData breakdownIdentity;

  @override
  State<BreakdownDetailsPage> createState() => _BreakdownDetailsPageState();
}

class _BreakdownDetailsPageState extends State<BreakdownDetailsPage> {
  BreakdownDetailsResponse? response;
  bool hasError = false;
  bool isRefreshing = false;

  Future<void> loadData() async {
    final cached = lovatAPI.getCachedBreakdownDetails(
      widget.team,
      widget.breakdownIdentity.path,
    );
    if (cached != null && response == null && !hasError) {
      setState(() {
        response = cached;
      });
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      final data = await lovatAPI.getBreakdownDetails(
        widget.team,
        widget.breakdownIdentity.path,
      );

      setState(() {
        response = data;
        hasError = false;
      });
    } catch (_) {
      if (response == null) {
        setState(() {
          hasError = true;
        });
      }
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = const Column(children: [LinearProgressIndicator()]);

    if (hasError && response == null) {
      body = FriendlyErrorView(onRetry: loadData);
    }

    if (response != null) {
      body = Stack(
        children: [
          ScrollablePageBody(
              children: response!.matchesWithSegments
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
            child: StaleRefreshIndicator(
              isRefreshing: isRefreshing,
              hasStaleData: response != null,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text("${widget.team} - ${widget.breakdownIdentity.localizedName}"),
      ),
      body: body,
    );
  }
}
