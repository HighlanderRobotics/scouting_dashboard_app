import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

class PicklistTeamBreakdownPage extends StatefulWidget {
  const PicklistTeamBreakdownPage({super.key});

  @override
  State<PicklistTeamBreakdownPage> createState() =>
      _PicklistTeamBreakdownPageState();
}

class _PicklistTeamBreakdownPageState extends State<PicklistTeamBreakdownPage> {
  bool useSameHeights = false;
  bool weighted = true;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    String teamNumber = routeArgs['team'].toString();
    String picklistTitle = routeArgs['picklistTitle'];
    List<Map<String, dynamic>> breakdown =
        routeArgs['breakdown'].cast<Map<String, dynamic>>();

    List<Map<String, dynamic>> unweightedBreakdown =
        routeArgs['unweighted'].cast<Map<String, dynamic>>();

    unweightedBreakdown
        .removeWhere((e) => e['result'] == 0 || e['result'] == null);
    unweightedBreakdown.sort((a, b) => b['result'].compareTo(a['result']));

    breakdown.removeWhere((e) => e['result'] == 0 || e['result'] == null);
    breakdown.sort((a, b) => (b['result'] as num).compareTo(a['result']));

    return Scaffold(
      appBar: AppBar(
        title: Text("$teamNumber - $picklistTitle Picklist"),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              weighted = !weighted;
            }),
            icon: Icon(weighted ? Icons.fitness_center : Icons.balance),
          ),
          IconButton(
            onPressed: () => setState(() {
              useSameHeights = !useSameHeights;
            }),
            icon: Icon(useSameHeights ? Icons.expand : Icons.compress),
          ),
        ],
      ),
      body: PageBody(
          child: Container(
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            color: Theme.of(context).colorScheme.primaryContainer),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:
                (weighted ? breakdown : unweightedBreakdown).map((weight) {
              bool alternate = (weight['result'] as num).isNegative
                  ? (weighted ? breakdown : unweightedBreakdown)
                      .indexOf(weight)
                      .isOdd
                  : (weighted ? breakdown : unweightedBreakdown)
                      .indexOf(weight)
                      .isEven;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubicEmphasized,
                key: Key(weight['type']),
                height: useSameHeights
                    ? (1 /
                            (weighted ? breakdown : unweightedBreakdown)
                                .length) *
                        constraints.maxHeight
                    : ((weight['result'] as num).abs() /
                            ((weighted ? breakdown : unweightedBreakdown)
                                .map((e) => (e['result'] as num).abs())
                                .toList()
                                .sum())) *
                        constraints.maxHeight,
                color: alternate
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          picklistWeights
                              .firstWhere((e) => e.path == weight['type'],
                                  orElse: () => PicklistWeight(
                                      weight['type'], weight['type']))
                              .localizedName,
                          overflow: TextOverflow.clip,
                          style: Theme.of(context).textTheme.titleMedium!.merge(
                              TextStyle(
                                  color: alternate
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer)),
                        ),
                        Text(
                          (weight['result'] as num).toStringAsFixed(2),
                          overflow: TextOverflow.clip,
                          style: Theme.of(context).textTheme.titleMedium!.merge(
                              TextStyle(
                                  color: alternate
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      )),
    );
  }
}
