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

  @override
  State<AnalysisVisualization> createState() => _AnalysisVisualizationState();
}

class _AnalysisVisualizationState extends State<AnalysisVisualization> {
  dynamic analysis;
  bool loaded = false;
  Object? error;

  @override
  void initState() {
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
