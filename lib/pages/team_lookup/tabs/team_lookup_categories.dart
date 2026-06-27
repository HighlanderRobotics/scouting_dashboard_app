import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_category_metrics.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:skeletons_forked/skeletons_forked.dart';

class TeamLookupCategoriesTab extends StatefulWidget {
  const TeamLookupCategoriesTab({super.key, required this.team});

  final int team;

  @override
  State<TeamLookupCategoriesTab> createState() =>
      _TeamLookupCategoriesTabState();
}

class _TeamLookupCategoriesTabState extends State<TeamLookupCategoriesTab> {
  CategoryMetrics? data;
  String? error;
  bool isRefreshing = false;

  Future<void> fetchData() async {
    // Show stale data from cache immediately
    final cached = lovatAPI.getCachedCategoryMetricsByTeamNumber(widget.team);
    if (cached != null && data == null && error == null) {
      setState(() {
        data = cached;
      });
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      final result = await lovatAPI.getCategoryMetricsByTeamNumber(widget.team);
      setState(() {
        data = result;
        error = null;
      });
    } on LovatAPIException catch (e) {
      if (data == null) {
        setState(() => error = e.message);
      }
    } catch (e) {
      debugPrint(e.toString());
      if (data == null) {
        setState(() => error = "Failed to load metrics");
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
  void didUpdateWidget(TeamLookupCategoriesTab oldWidget) {
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
              children: [
                MetricCategoryList(
                  metricCategories: metricCategories
                      .map((category) => MetricCategory(
                            categoryName: category.localizedName,
                            metricTiles: category.metrics
                                .where((metric) => metric.hideOverview == false)
                                .map(
                                  (metric) => MetricTile(
                                    value: (() {
                                      try {
                                        return metric.valueVizualizationBuilder(
                                            data!.valueForMetric(metric));
                                      } catch (_) {
                                        return "--";
                                      }
                                    })(),
                                    label: metric.abbreviatedLocalizedName,
                                    onTap: metric.hideDetails
                                        ? null
                                        : () {
                                            Navigator.of(context).pushNamed(
                                                "/team_lookup_details",
                                                arguments: {
                                                  'category': category,
                                                  'metric': metric.path,
                                                  'team': widget.team,
                                                });
                                          },
                                  ),
                                )
                                .toList(),
                            onTap: category.metrics
                                    .where((metric) => !metric.hideDetails)
                                    .isEmpty
                                ? null
                                : () {
                                    Navigator.of(context).pushNamed(
                                        "/team_lookup_details",
                                        arguments: {
                                          'category': category,
                                          'team': widget.team,
                                        });
                                  },
                          ))
                      .toList(),
                ),
              ],
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
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: SkeletonListView(
        itemCount: metricCategories.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: SizedBox(
            height: 117,
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
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: Theme.of(context).colorScheme.primaryContainer,
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
                                    .onPrimaryContainer,
                              ),
                            ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: metricTiles,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.navigate_next,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
    this.onTap,
  }) : super(key: key);

  final String value;
  final String label;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget contents = Container(
      constraints: const BoxConstraints(minWidth: 70),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

    if (onTap == null) return contents;

    return GestureDetector(
      onTap: onTap,
      child: contents,
    );
  }
}
