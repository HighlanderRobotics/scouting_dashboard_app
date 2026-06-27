import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/pages/team_lookup/team_lookup_breakdown_details.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_breakdown_metrics.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:skeletons_forked/skeletons_forked.dart';

class TeamLookupBreakdownsTab extends StatefulWidget {
  const TeamLookupBreakdownsTab({super.key, required this.team});

  final int team;

  @override
  State<TeamLookupBreakdownsTab> createState() =>
      _TeamLookupBreakdownsTabState();
}

class _TeamLookupBreakdownsTabState extends State<TeamLookupBreakdownsTab> {
  BreakdownMetrics? data;
  String? error;
  bool isRefreshing = false;

  Future<void> fetchData() async {
    // Show stale data from cache immediately
    final cached = lovatAPI.getCachedBreakdownMetricsByTeamNumber(widget.team);
    if (cached != null && data == null && error == null) {
      setState(() {
        data = cached;
      });
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      final result =
          await lovatAPI.getBreakdownMetricsByTeamNumber(widget.team);
      setState(() {
        data = result;
        error = null;
      });
    } on LovatAPIException catch (e) {
      if (data == null) {
        setState(() => error = e.message);
      }
    } catch (_) {
      if (data == null) {
        setState(() => error = "Failed to load breakdowns");
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
    fetchData();
  }

  @override
  void didUpdateWidget(TeamLookupBreakdownsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.team != widget.team) {
      setState(() {
        data = null;
        error = null;
      });
      fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data != null) {
      return Stack(
        children: [
          ScrollablePageBody(
            children: breakdowns
                .map(
                  (BreakdownData breakdownData) => Breakdown(
                    dataIdentity: breakdownData,
                    data: data!,
                    team: widget.team,
                  ),
                )
                .toList(),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StaleRefreshIndicator(
              isRefreshing: isRefreshing,
              hasStaleData: data != null,
            ),
          ),
        ],
      );
    }

    if (error != null) {
      if (error!.contains("NO_DATA_FOR_TEAM")) {
        return PageBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/no_scouters.png", width: 250),
              const SizedBox(height: 8),
              Text(
                "No data found",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                "Try using data from more teams or tournaments.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      if (error!.contains("TEAM_DOES_NOT_EXIST")) {
        return PageBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/awaiting_verification.png",
                  width: 250),
              const SizedBox(height: 8),
              Text(
                "Team does not exist",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return FriendlyErrorView(errorMessage: error, onRetry: fetchData);
    }

    return PageBody(
      bottom: false,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: SkeletonListView(
        itemCount: breakdowns.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            height: 118,
            child: SkeletonAvatar(
              style: SkeletonAvatarStyle(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Breakdown extends StatelessWidget {
  const Breakdown({
    super.key,
    required this.dataIdentity,
    required this.data,
    required this.team,
  });

  final BreakdownData dataIdentity;
  final BreakdownMetrics data;
  final int team;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushWidget(
          BreakdownDetailsPage(team: team, breakdownIdentity: dataIdentity)),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dataIdentity.localizedName,
                        style: Theme.of(context).textTheme.titleMedium!.merge(
                              TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                      ),
                      Icon(
                        Icons.navigate_next,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  data.isEmpty(dataIdentity.path)
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          height: 64,
                          child: const Center(child: Text("None recorded")),
                        )
                      : ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(6)),
                          child: IntrinsicHeight(
                            child: Row(
                                children: dataIdentity.segments
                                    .where((segmentData) =>
                                        data.segmentValue(dataIdentity.path,
                                            segmentData.path) !=
                                        0)
                                    .map((BreakdownSegmentData segmentData) {
                              final analyzedSegmentValue = data.segmentValue(
                                  dataIdentity.path, segmentData.path);

                              return segment(
                                context,
                                analyzedSegmentValue == 1
                                    ? segmentData.localizedNameSingular
                                    : (segmentData.localizedNamePlural ??
                                        segmentData.localizedNameSingular),
                                analyzedSegmentValue,
                                (dataIdentity.segments.indexOf(segmentData) /
                                            dataIdentity.segments.length) *
                                        0.7 +
                                    0.3,
                              );
                            }).toList()),
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Flexible segment(
      BuildContext context, String name, double value, double colorFactor) {
    return Flexible(
      flex: (value * 1000).round(),
      fit: FlexFit.tight,
      child: Tooltip(
        message: "$name - ${(value * 100).round()}%",
        child: Container(
          color: Color.lerp(
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
            colorFactor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${(value * 100).round()}%",
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
