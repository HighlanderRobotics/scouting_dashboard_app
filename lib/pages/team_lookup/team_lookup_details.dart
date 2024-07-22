import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_metric_details_analysis.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';

import 'package:http/http.dart' as http;

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

    return DefaultTabController(
      length: metricsToShow.length,
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
        if (analysisMap.containsKey('one') &&
            analysisMap.containsKey('two') &&
            analysisMap.containsKey('three'))
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    gridRow(context, analysisMap, 'three', 'Top'),
                    Divider(
                      height: 21,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    gridRow(context, analysisMap, 'two', 'Middle'),
                    Divider(
                      height: 21,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    gridRow(context, analysisMap, 'one', 'Hybrid'),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        if (analysisFunction.metric.path == "pentalties") ...[
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
                    "Matches",
                    style: Theme.of(context).textTheme.titleMedium!.merge(
                          TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                  ),
                  if (analysisMap['matches'].isEmpty)
                    Text(
                      "No penalties in any matches",
                      style: Theme.of(context).textTheme.bodyMedium!.merge(
                            TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                    ),
                  ...((analysisMap['matches'] as List<dynamic>).map((matchMap) {
                    final match =
                        GameMatchIdentity.fromLongKey(matchMap['match']);

                    final penalty = Penalty.values[matchMap['cardType']];

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          style: Theme.of(context).textTheme.bodyMedium!.merge(
                                TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                          match.getLocalizedDescription(
                            includeTournament: false,
                          ),
                        ),
                        Text(
                          style: Theme.of(context).textTheme.bodyMedium!.merge(
                                TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                          penalty.localizedDescription,
                        )
                      ],
                    );
                  }).toList())
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
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
        if (analysisFunction.metric.path == "avgTeleScore")
          ScoringBreakdown(analysisMap, analysisFunction.teamNumber),
      ],
    );
  }

  Row gridRow(
    BuildContext context,
    Map<String, dynamic> analysisMap,
    String key,
    String label,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge!.merge(
                TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        ),
        Text(
          analysisFunction.metric.valueVizualizationBuilder(analysisMap[key]),
          style: Theme.of(context).textTheme.titleLarge,
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
              color: Theme.of(context).colorScheme.surfaceVariant,
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

                              debugPrint(
                                  "Match: ${snapshot.data['array'][touchedSpot.spotIndex]}");

                              return LineTooltipItem(
                                "${matchIdentity.getShortLocalizedDescription()} at ${snapshot.data['array'][touchedSpot.spotIndex]['tournamentName']}",
                                Theme.of(context).textTheme.labelMedium!,
                              );
                            }).toList();
                          },
                        )),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(),
                          topTitles: AxisTitles(),
                          leftTitles: AxisTitles(
                            axisNameWidget: Text(analysisFunction
                                .metric.abbreviatedLocalizedName),
                            sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) =>
                                    SideTitleWidget(
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
                              final List array = snapshot.data['array'];

                              List<FlSpot> spots = [];

                              for (var i = 0; i < array.length; i++) {
                                if (array[i]["dataPoint"] != null) {
                                  debugPrint("Spot: ${array[i]["dataPoint"]}");
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

class ScoringBreakdown extends StatefulWidget {
  const ScoringBreakdown(this.detailsAnalysisMap, this.team, {super.key});

  final Map<String, dynamic> detailsAnalysisMap;
  final int team;

  @override
  State<ScoringBreakdown> createState() => _ScoringBreakdownState();
}

class _ScoringBreakdownState extends State<ScoringBreakdown> {
  List<String>? matchKeys;

  GameMatchIdentity? selectedMatch;

  Map<String, num?>? data;
  bool loading = true;

  @override
  Widget build(BuildContext context) {
    matchKeys ??= (widget.detailsAnalysisMap['array'] as List<dynamic>)
        .map((e) => e['match'])
        .toList()
        .cast();

    matchKeys!.sort(
      (a, b) => GameMatchIdentity.fromLongKey(a)
          .number
          .compareTo(GameMatchIdentity.fromLongKey(b).number),
    );

    if (loading == true) {
      (() async {
        Map<String, dynamic> queryParams = {
          "team": widget.team.toString(),
        };

        if (selectedMatch != null) {
          queryParams['tournamentKey'] = selectedMatch!.tournamentKey;
          queryParams['matchNumber'] = selectedMatch!.number.toString();
          queryParams['matchType'] = selectedMatch!.type.shortName;
        }

        final response = await http.get(
          Uri.http((await getServerAuthority())!,
              "/API/analysis/scoringBreakdown", queryParams),
        );

        setState(() {
          loading = false;
          data = jsonDecode(utf8.decode(response.bodyBytes))[0]
                  ['scoringBreakdown']
              .cast<String, num>();
        });
      })();
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: matchKeys!.isEmpty
                      ? const Center(
                          child: Text("No matches"),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(15),
                          child: LayoutBuilder(builder: (context, constraints) {
                            return ColorFiltered(
                              colorFilter: loading
                                  ? const ColorFilter.matrix([
                                      0.2126,
                                      0.7152,
                                      0.0722,
                                      0,
                                      0,
                                      0.2126,
                                      0.7152,
                                      0.0722,
                                      0,
                                      0,
                                      0.2126,
                                      0.7152,
                                      0.0722,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      1,
                                      0,
                                    ])
                                  : const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.overlay,
                                    ),
                              child: data != null &&
                                      data!.keys
                                          .every((key) => data![key] == null)
                                  ? Center(
                                      child: loading
                                          ? const CircularProgressIndicator()
                                          : Text(
                                              "${widget.team} did not score during ${selectedMatch == null ? 'any matches' : selectedMatch!.getLocalizedDescription(includeTournament: false).toLowerCase()}."),
                                    )
                                  : PieChart(
                                      PieChartData(
                                        sections: data == null
                                            ? [
                                                PieChartSectionData(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  radius: min(
                                                          constraints.maxWidth,
                                                          constraints
                                                              .maxHeight) /
                                                      2,
                                                ),
                                              ]
                                            : data!.keys
                                                .map(
                                                  (e) => PieChartSectionData(
                                                    radius: min(
                                                            constraints
                                                                .maxWidth,
                                                            constraints
                                                                .maxHeight) /
                                                        2,
                                                    title:
                                                        "${(data![e]!.toDouble() * 100).round()}%\n${scoringMethods.any((f) => f.path == e) ? scoringMethods.firstWhere((f) => f.path == e).localizedName : e}",
                                                    value: data![e]!.toDouble(),
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    titleStyle: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        centerSpaceRadius: 0,
                                        borderData: FlBorderData(show: false),
                                      ),
                                    ),
                            );
                          }),
                        ),
                ),
                if (matchKeys!.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.scrim,
                    ),
                    child: Slider(
                      value: selectedMatch == null
                          ? 0
                          : matchKeys!.indexWhere((e) =>
                                  GameMatchIdentity.fromLongKey(e).number ==
                                      selectedMatch!.number &&
                                  GameMatchIdentity.fromLongKey(e).type ==
                                      selectedMatch!.type) +
                              1,
                      min: 0,
                      max: matchKeys!.length.toDouble(),
                      onChanged: (value) {
                        HapticFeedback.selectionClick();

                        if (value == 0) {
                          setState(() {
                            selectedMatch = null;

                            loading = true;
                          });
                        } else {
                          setState(() {
                            selectedMatch = GameMatchIdentity.fromLongKey(
                                matchKeys![value.toInt() - 1]);

                            loading = true;
                          });
                        }
                      },
                      divisions: matchKeys!.length,
                      label: selectedMatch == null
                          ? "All"
                          : selectedMatch!.getLocalizedDescription(
                              includeTournament: false),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
