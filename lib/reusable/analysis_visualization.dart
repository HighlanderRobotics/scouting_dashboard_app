import 'package:flutter/material.dart';

import '../analysis_functions/analysis.dart';

abstract class AnalysisVisualization extends StatefulWidget {
  const AnalysisVisualization({
    GlobalKey<AnalysisVisualizationState>? key,
    required this.analysisFunction,
    this.updateIncrement = 0,
  }) : super(key: key);

  final AnalysisFunction analysisFunction;
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

    return widget.loadedData(context, analysis);
  }
}
