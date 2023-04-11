import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_breakdowns_analysis.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class TeamLookupBreakdownsVizualization extends AnalysisVisualization {
  const TeamLookupBreakdownsVizualization({
    super.key,
    required this.function,
  }) : super(analysisFunction: function);

  final TeamLookupBreakdownsAnalysis function;

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
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed('/team_lookup_breakdown_details',
            arguments: <String, dynamic>{
              'matches': data[dataIdentity.path]!['array'],
              'breakdownData': dataIdentity,
              'team': team,
            });
      },
      child: Column(
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
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: Row(
                        children: dataIdentity.segments
                            .map((BreakdownSegmentData segmentData) {
                      int analyzedSegmentValue = data
                          .cast()[dataIdentity.path]!
                          .cast()[segmentData.path]!;

                      if (analyzedSegmentValue == 0) {
                        return Container();
                      }

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
      BuildContext context, String name, int value, double colorFactor) {
    return Flexible(
      flex: value,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.titleLarge,
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
