import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_metric_details_analysis.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';

class TeamLookupDetails extends StatefulWidget {
  const TeamLookupDetails({super.key});

  @override
  State<TeamLookupDetails> createState() => _TeamLookupDetailsState();
}

class _TeamLookupDetailsState extends State<TeamLookupDetails> {
  int? matchCount;
  RangeValues timeSliderValues = const RangeValues(0, 1);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    MetricCategoryData category = routeArgs['category'];
    int teamNumber = routeArgs['team'];

    return DefaultTabController(
      length: category.metrics.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("$teamNumber - ${category.localizedName}"),
          bottom: TabBar(
            tabs: category.metrics
                .map((metric) => Tab(
                      text: metric.localizedName,
                    ))
                .toList(),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: TabBarView(
          children: category.metrics
              .map((metric) => ListView(
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

class AnalysisOverview extends AnalysisVisualization {
  const AnalysisOverview({
    super.key,
    required this.analysisFunction,
  }) : super(analysisFunction: analysisFunction);

  final TeamMetricDetailsAnalysis analysisFunction;

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(children: [
        AspectRatio(
          aspectRatio: 364 / 229,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                      bottomTitles:
                          AxisTitles(axisNameWidget: const Text("Match")),
                      topTitles: AxisTitles(),
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                            analysisFunction.metric.abbreviatedLocalizedName),
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    analysisFunction.metric
                                        .valueVizualizationBuilder(value),
                                  ),
                                ),
                            reservedSize: 50),
                      ),
                      rightTitles: AxisTitles()),
                  lineBarsData: [
                    LineChartBarData(
                      spots: (() {
                        final List array = snapshot.data['array'];

                        List<FlSpot> spots = [];

                        for (var i = 0; i < array.length; i++) {
                          spots.add(FlSpot(i.toDouble(), array[i].toDouble()));
                        }

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
      ]),
    );
  }
}
