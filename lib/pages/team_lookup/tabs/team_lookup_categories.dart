import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/team_lookup_categories_analysis.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/analysis_visualization.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class TeamLookupCategoriesVizualization extends AnalysisVisualization {
  const TeamLookupCategoriesVizualization({
    super.key,
    required this.function,
  }) : super(analysisFunction: function);

  final TeamLookupCategoriesAnalysis function;

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    return ScrollablePageBody(
      children: [
        MetricCategoryList(
          metricCategories: metricCategories
              .map((category) => MetricCategory(
                    categoryName: category.localizedName,
                    metricTiles: category.metrics
                        .map(
                          (metric) => MetricTile(
                            value: (() {
                              try {
                                return metric.valueVizualizationBuilder(
                                    snapshot.data[metric.path]);
                              } catch (error) {
                                return "--";
                              }
                            })(),
                            label: metric.abbreviatedLocalizedName,
                          ),
                        )
                        .toList(),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed("/team_lookup_details", arguments: {
                        'category': category,
                        'team': function.team,
                      });
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class MetricCategoryList extends StatelessWidget {
  const MetricCategoryList({
    Key? key,
    this.metricCategories = const [],
  }) : super(key: key);

  final List<MetricCategory> metricCategories;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: metricCategories
          .expand((element) => [element, const SizedBox(height: 15)])
          .take(metricCategories.length * 2 - 1)
          .toList(),
    );
  }
}

class MetricCategory extends StatelessWidget {
  const MetricCategory({
    Key? key,
    required this.categoryName,
    this.metricTiles = const <MetricTile>[],
    this.onTap,
  }) : super(key: key);

  final String categoryName;
  final List<MetricTile> metricTiles;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: Theme.of(context).textTheme.titleMedium!.merge(
                              TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: metricTiles
                            .expand((element) =>
                                [element, const SizedBox(width: 10)])
                            .take(metricTiles.length * 2 - 1)
                            .toList(),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.navigate_next,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    Key? key,
    required this.value,
    required this.label,
  }) : super(key: key);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall!.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium!.merge(TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
