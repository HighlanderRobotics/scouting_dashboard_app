import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_breakdowns_analysis.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:skeletons/skeletons.dart';

class TeamLookupBreakdownsVizualization extends AnalysisVisualization {
  const TeamLookupBreakdownsVizualization({
    super.key,
    required this.function,
    super.updateIncrement,
  }) : super(analysisFunction: function);

  final TeamLookupBreakdownsAnalysis function;

  @override
  Widget loadingView() {
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

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    return ScrollablePageBody(
      children: breakdowns
          .map(
            (BreakdownData breakdownData) => Breakdown(
              dataIdentity: breakdownData,
              data: (snapshot.data as Map<String, dynamic>).cast(),
              team: function.team,
            ),
          )
          .toList(),
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
  final Map<String, Map<String, dynamic>> data;
  final int team;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dataIdentity.localizedName,
                  style: Theme.of(context).textTheme.titleMedium!.merge(
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                ),
                const SizedBox(height: 10),
                data[dataIdentity.path] == null ||
                        data[dataIdentity.path]!.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Theme.of(context).colorScheme.background,
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
                                      (data.cast()[dataIdentity.path]
                                              [segmentData.path] ??
                                          0) !=
                                      0)
                                  .map((BreakdownSegmentData segmentData) {
                            double analyzedSegmentValue =
                                data[dataIdentity.path]?[segmentData.path]
                                        ?.toDouble() ??
                                    0;

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
    );
  }

  Flexible segment(
      BuildContext context, String name, double value, double colorFactor) {
    return Flexible(
      flex: (value * 1000).round(),
      fit: FlexFit.tight,
      child: Container(
        // color: Theme.of(context).colorScheme.primary,
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
    );
  }
}
