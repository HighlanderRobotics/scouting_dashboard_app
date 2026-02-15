import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

import '../analysis_functions/analysis.dart';

abstract class AnalysisVisualization<T extends AnalysisFunction>
    extends StatefulWidget {
  const AnalysisVisualization({
    GlobalKey<AnalysisVisualizationState>? key,
    required this.analysisFunction,
    this.updateIncrement = 0,
  }) : super(key: key);

  final T analysisFunction;
  final int updateIncrement;

  Widget loadingView() => const Center(child: CircularProgressIndicator());
  Widget loadedData(BuildContext context, AsyncSnapshot<dynamic> snapshot);

  void loadData() {
    final state = key as GlobalKey<AnalysisVisualizationState>;
    state.currentState?.loadData();
  }

  @override
  State<AnalysisVisualization> createState() => AnalysisVisualizationState();
}

class AnalysisVisualizationState extends State<AnalysisVisualization> {
  dynamic analysis;
  bool loaded = false;
  Object? error;
  int? displayedIncrement;

  void loadData() {
    final targetIncrement = widget.updateIncrement;

    setState(() {
      analysis = null;
      loaded = false;
      error = null;
    });

    widget.analysisFunction.getAnalysis().then((value) {
      setState(
        () {
          loaded = true;
          displayedIncrement = targetIncrement;
          analysis = AsyncSnapshot.withData(ConnectionState.done, value);
        },
      );
    }).catchError((err) {
      setState(() {
        loaded = true;
        displayedIncrement = targetIncrement;
        error = err;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (displayedIncrement != widget.updateIncrement) {
      loadData();
    }
    if (!loaded) {
      return widget.loadingView();
    }

    if (error != null) {
      if (error.toString().contains("NO_DATA_FOR_TEAM")) {
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
              )
            ],
          ),
        );
      } else if (error.toString().contains("TEAM_DOES_NOT_EXIST")) {
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
      } else {
        return Center(
          child: IconButton(
            icon: const Icon(Icons.sentiment_dissatisfied_outlined),
            tooltip: "Show error details",
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text("Error"),
                        content: Text(error.toString()),
                        actions: [
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Dismiss"),
                          ),
                        ],
                      ));
            },
          ),
        );
      }
    }

    return widget.loadedData(context, analysis);
  }
}
