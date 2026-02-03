import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_metric_details_analysis.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/models/match.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';

class TeamLookupDetailsPage extends StatefulWidget {
  const TeamLookupDetailsPage({super.key});

  @override
  State<TeamLookupDetailsPage> createState() => _TeamLookupDetailsPageState();
}

class _TeamLookupDetailsPageState extends State<TeamLookupDetailsPage> {
  int? matchCount;
  RangeValues timeSliderValues = const RangeValues(0, 1);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    MetricCategoryData category = routeArgs['category'];
    int teamNumber = routeArgs['team'];

    List<CategoryMetric> metricsToShow =
        category.metrics.where(((metric) => !metric.hideDetails)).toList();

    int selectedMetricIndex =
        metricsToShow.indexWhere((m) => m.path == routeArgs['metric']);

    debugPrint(routeArgs['metric']);

    return DefaultTabController(
      length: metricsToShow.length,
      initialIndex: selectedMetricIndex == -1 ? 0 : selectedMetricIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text("$teamNumber - ${category.localizedName}"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(49),
            child: Column(
              children: [
                TabBar(
                  tabs: metricsToShow
                      .map((metric) => Tab(
                            text: metric.abbreviatedLocalizedName,
                          ))
                      .toList(),
                  labelColor: Theme.of(context).colorScheme.primary,
                  labelStyle: Theme.of(context).textTheme.titleSmall,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  indicatorPadding: const EdgeInsets.fromLTRB(2, 46, 2, 0),
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: metricsToShow
              .map((metric) => ScrollablePageBody(
                    children: [
                      if (matchCount != null)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Oldest",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  ),
                                  Text(
                                    "Most recent",
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                            RangeSlider(
                              values: timeSliderValues,
                              onChanged: ((RangeValues newRange) {
                                setState(() {
                                  timeSliderValues = newRange;
                                });
                              }),
                              min: 0,
                              max: matchCount!.toDouble(),
                              divisions: matchCount!,
                            ),
                          ],
                        ),
                      AnalysisOverview(
                        analysisFunction: TeamMetricDetailsAnalysis(
                          teamNumber: teamNumber,
                          metric: metric,
                        ),
                      )
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class AnalysisOverview
    extends AnalysisVisualization<TeamMetricDetailsAnalysis> {
  const AnalysisOverview({
    super.key,
    required super.analysisFunction,
  });

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    Map<String, dynamic> analysisMap = snapshot.data;

    return Column(
      children: [
        Row(children: [
          if (analysisMap.containsKey('result'))
            valueBox(
              context,
              Text(
                analysisFunction.metric
                    .valueVizualizationBuilder(snapshot.data['result']),
                style: Theme.of(context).textTheme.headlineSmall!.merge(
                      TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
              ),
              "This team",
              false,
            ),
          const SizedBox(width: 10),
          if (analysisMap.containsKey('all'))
            Flexible(
              flex: 5,
              fit: FlexFit.tight,
              child: valueBox(
                context,
                Text(
                  analysisFunction.metric
                      .valueVizualizationBuilder(snapshot.data['all']),
                  style: Theme.of(context).textTheme.headlineSmall!.merge(
                        TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
                ),
                "All teams",
                true,
              ),
            ),
          const SizedBox(width: 10),
          if (analysisMap.containsKey('difference'))
            Flexible(
              flex: 6,
              fit: FlexFit.tight,
              child: valueBox(
                context,
                analysisMap['difference'] == null
                    ? Text(
                        "--",
                        style: Theme.of(context).textTheme.headlineSmall!.merge(
                              TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer),
                            ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (snapshot.data['difference'] as num).isNegative
                                ? Icons.arrow_drop_down
                                : Icons.arrow_drop_up,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                          Text(
                            analysisFunction.metric.valueVizualizationBuilder(
                                (snapshot.data['difference'] as num).abs()),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .merge(
                                  TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer),
                                ),
                          ),
                        ],
                      ),
                "Difference",
                false,
              ),
            ),
        ]),
        if (analysisMap.containsKey('array')) ...[
          const SizedBox(height: 10),
          sparkline(context, snapshot, analysisFunction.metric.max),
        ],
        if (analysisMap.containsKey('paths'))
          TeamAutoPaths(
            autoPaths: (analysisMap['paths'] as List<dynamic>)
                .map((e) => AutoPath.fromMap(e))
                .toList(),
          ),
      ],
    );
  }

  Widget sparkline(
      BuildContext context, AsyncSnapshot<dynamic> snapshot, double? max) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 364 / 229,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: snapshot.data['array'].isEmpty
                ? const Center(
                    child: Text("No matches"),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: max,
                        lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              final matchIdentity =
                                  GameMatchIdentity.fromLongKey(
                                      snapshot.data['array']
                                          [touchedSpot.spotIndex]['match']);

                              return LineTooltipItem(
                                "${matchIdentity.getShortLocalizedDescription()} at ${snapshot.data['array'][touchedSpot.spotIndex]['tournamentName']}",
                                Theme.of(context).textTheme.labelMedium!,
                              );
                            }).toList();
                          },
                        )),
                        titlesData: FlTitlesData(
                          bottomTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            axisNameWidget: Text(analysisFunction
                                .metric.abbreviatedLocalizedName),
                            sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) =>
                                    SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        analysisFunction.metric
                                            .valueVizualizationBuilder(value),
                                      ),
                                    ),
                                reservedSize: 50),
                          ),
                          rightTitles: const AxisTitles(),
                        ),
                        borderData: FlBorderData(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        gridData: FlGridData(
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Theme.of(context).colorScheme.outline,
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Theme.of(context).colorScheme.outline,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: (() {
                              final List array = snapshot.data['array'];

                              List<FlSpot> spots = [];

                              for (var i = 0; i < array.length; i++) {
                                if (array[i]["dataPoint"] != null) {
                                  spots.add(
                                    FlSpot(
                                      i.toDouble(),
                                      array[i]["dataPoint"].toDouble(),
                                    ),
                                  );
                                }
                              }

                              spots.sort((a, b) => a.x.compareTo(b.x));

                              return spots;
                            })(),
                            isCurved: true,
                            curveSmoothness: 0.4,
                            preventCurveOverShooting: true,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 11),
      ],
    );
  }
}

Container valueBox(BuildContext context, Widget value, String description,
    bool alternateColorScheme) {
  return Container(
    decoration: BoxDecoration(
      color: alternateColorScheme
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.primaryContainer,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          value,
          Text(
            description,
            style: Theme.of(context).textTheme.labelMedium!.merge(
                  TextStyle(
                      color: alternateColorScheme
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onPrimaryContainer),
                ),
          ),
        ],
      ),
    ),
  );
}
