import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_metric_details_analysis.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(49),
            child: Column(
              children: [
                TabBar(
                  tabs: category.metrics
                      .map((metric) => Tab(
                            text: metric.localizedName,
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
                const Divider(height: 1),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: category.metrics
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

class AnalysisOverview extends AnalysisVisualization {
  const AnalysisOverview({
    super.key,
    required this.analysisFunction,
  }) : super(analysisFunction: analysisFunction);

  final TeamMetricDetailsAnalysis analysisFunction;

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    return Column(children: [
      if ((snapshot.data as Map<String, dynamic>).containsKey('array'))
        sparkline(context, snapshot),
      Row(
        children: [
          if ((snapshot.data as Map<String, dynamic>).containsKey('result'))
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
              "Average",
              false,
            ),
        ],
      )
    ]);
  }

  Container valueBox(BuildContext context, Widget value, String description,
      bool alternateColorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
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
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sparkline(BuildContext context, AsyncSnapshot<dynamic> snapshot) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 364 / 229,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: FutureBuilder(future: (() async {
              return await TournamentSchedule.fromServer(
                (await getServerAuthority())!,
                (await SharedPreferences.getInstance())
                    .getString("tournament")!,
              );
            })(), builder: (context, scheduleSnapshot) {
              if (scheduleSnapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                          axisNameWidget: const Text("Match"),
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Text(
                              scheduleSnapshot
                                  .data!.matches[value.toInt()].identity
                                  .getShortLocalizedDescription(),
                            ),
                          )),
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
                      rightTitles: AxisTitles(),
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
                          final TournamentSchedule schedule =
                              scheduleSnapshot.data!;
                          final List array = snapshot.data['array'];

                          List<FlSpot> spots = [];

                          for (var i = 0; i < array.length; i++) {
                            spots.add(
                              FlSpot(
                                schedule.matches
                                    .firstWhere(
                                      (match) =>
                                          match.identity.toMediumKey() ==
                                          (array[i]["match"] as String)
                                              .replaceAll(
                                                  RegExp('_\\d+\$'), ""),
                                    )
                                    .ordinalNumber
                                    .toDouble(),
                                array[i]["value"].toDouble(),
                              ),
                            );
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
              );
            }),
          ),
        ),
        const SizedBox(height: 11),
      ],
    );
  }
}
