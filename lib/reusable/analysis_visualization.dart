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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Icon(Icons.sentiment_dissatisfied_outlined);
          }

          return loadedData(context, snapshot);
        });
  }

  Widget loadedData(BuildContext context, AsyncSnapshot<dynamic> snapshot);
}
