import 'package:flutter/material.dart';

import '../analysis_functions/analysis.dart';

abstract class AnalysisVisualization extends StatelessWidget {
  const AnalysisVisualization({
    Key? key,
    required this.analysisFunction,
  }) : super(key: key);

  final AnalysisFunction analysisFunction;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: analysisFunction.getAnalysis(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return loadingView();
          }

          if (snapshot.hasError) {
            return Center(
              child: IconButton(
                icon: const Icon(Icons.sentiment_dissatisfied_outlined),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: const Text("Error"),
                            content: Text(snapshot.error.toString()),
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

          return loadedData(context, snapshot);
        });
  }

  Widget loadingView() => const Center(child: CircularProgressIndicator());

  Widget loadedData(BuildContext context, AsyncSnapshot<dynamic> snapshot);
}
