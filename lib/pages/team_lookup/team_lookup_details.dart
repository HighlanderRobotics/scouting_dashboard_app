import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_metric_details.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';
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
                        teamNumber: teamNumber,
                        metric: metric,
                      ),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class AnalysisOverview extends StatelessWidget {
  const AnalysisOverview({
    super.key,
    required this.teamNumber,
    required this.metric,
  });

  final int teamNumber;
  final CategoryMetric metric;

  @override
  Widget build(BuildContext context) {
    return StaleRefreshBuilder(
      query: lovatAPI.metricDetails(teamNumber, metric.path),
      builder: (context, result) {
        final data = result.data;
        final error = result.error;
        if (error != null && data == null) {
          return FriendlyErrorView.result(result);
        }

        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final d = data;

        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Row(children: [
                    if (d.hasResult)
                      valueBox(
                        context,
                        Text(
                          metric.valueVizualizationBuilder(d.result),
                          style:
                              Theme.of(context).textTheme.headlineSmall!.merge(
                                    TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                  ),
                        ),
                        "This team",
                        false,
                      ),
                    if (d.hasResult) const SizedBox(width: 10),
                    if (d.hasAll)
                      Flexible(
                        flex: 5,
                        fit: FlexFit.tight,
                        child: valueBox(
                          context,
                          Text(
                            metric.valueVizualizationBuilder(d.all),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .merge(
                                  TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary),
                                ),
                          ),
                          "All teams",
                          true,
                        ),
                      ),
                    if (d.hasAll) const SizedBox(width: 10),
                    if (d.hasDifference)
                      Flexible(
                        flex: 6,
                        fit: FlexFit.tight,
                        child: valueBox(
                          context,
                          d.difference == null
                              ? Text(
                                  "--",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .merge(
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
                                      d.difference!.isNegative
                                          ? Icons.arrow_drop_down
                                          : Icons.arrow_drop_up,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                    Text(
                                      metric.valueVizualizationBuilder(
                                          d.difference!.abs()),
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
                  if (d.array.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    sparkline(context, d, metric.max),
                  ],
                  if (d.paths.isNotEmpty)
                    TeamAutoPaths(
                      autoPaths: d.paths,
                    ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: StaleRefreshIndicator.result(result),
            ),
          ],
        );
      },
    );
  }

  Widget sparkline(BuildContext context, MetricDetails data, double? max) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 364 / 229,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: data.array.isEmpty
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
                              final dataPoint =
                                  data.array[touchedSpot.spotIndex];

                              return LineTooltipItem(
                                "${dataPoint.match.getShortLocalizedDescription()} at ${dataPoint.tournamentName}",
                                Theme.of(context).textTheme.labelMedium!,
                              );
                            }).toList();
                          },
                        )),
                        titlesData: FlTitlesData(
                          bottomTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            axisNameWidget: Text(
                              metric.abbreviatedNameWithUnits,
                            ),
                            sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final interval = meta.appliedInterval;
                                  final isAligned =
                                      value % interval > interval / 2;

                                  if (value == meta.max &&
                                      !isAligned &&
                                      max == null) {
                                    return const Text("");
                                  }

                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(numToStringRounded(value)),
                                  );
                                },
                                reservedSize: 40),
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
                              List<FlSpot> spots = [];

                              for (var i = 0; i < data.array.length; i++) {
                                if (data.array[i].dataPoint != null) {
                                  spots.add(
                                    FlSpot(
                                      i.toDouble(),
                                      data.array[i].dataPoint!,
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
