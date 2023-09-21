import 'package:flutter/material.dart';

import '../analysis_functions/analysis.dart';

abstract class AnalysisVisualization extends StatefulWidget {
  const AnalysisVisualization({
    Key? key,
    required this.analysisFunction,
  }) : super(key: key);

  final AnalysisFunction analysisFunction;

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

  void loadData() {
    setState(() {
      analysis = null;
      loaded = false;
      error = null;
    });

    widget.analysisFunction.getAnalysis().then((value) {
      setState(
        () {
          loaded = true;
          analysis = AsyncSnapshot.withData(ConnectionState.done, value);
        },
      );
    }).catchError((err) {
      setState(() {
        loaded = true;
        error = err;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return widget.loadingView();
    }

    if (error != null) {
      return Center(
        child: IconButton(
          icon: const Icon(Icons.sentiment_dissatisfied_outlined),
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
