import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/analysis_functions/score_predictor_analysis.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

import '../reusable/analysis_visualization.dart';

class ScorePredictor extends StatefulWidget {
  const ScorePredictor({super.key});

  @override
  State<ScorePredictor> createState() => _ScorePredictorState();
}

class _ScorePredictorState extends State<ScorePredictor> {
  String blue1FieldValue = "";
  String blue2FieldValue = "";
  String blue3FieldValue = "";
  String red1FieldValue = "";
  String red2FieldValue = "";
  String red3FieldValue = "";

  ScorePredictorAnalysis? analysisFunction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Score Predictor")),
      body: ScrollablePageBody(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Red Alliance"),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  filled: true,
                  labelText: "Team 1",
                ),
                onChanged: (value) {
                  setState(() {
                    analysisFunction = null;
                    red1FieldValue = value;
                  });
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  filled: true,
                  labelText: "Team 2",
                ),
                onChanged: (value) {
                  setState(() {
                    analysisFunction = null;
                    red2FieldValue = value;
                  });
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  filled: true,
                  labelText: "Team 3",
                ),
                onChanged: (value) {
                  setState(() {
                    analysisFunction = null;
                    red3FieldValue = value;
                  });
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Blue Alliance"),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  filled: true,
                  labelText: "Team 1",
                ),
                onChanged: (value) {
                  setState(() {
                    analysisFunction = null;
                    blue1FieldValue = value;
                  });
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  filled: true,
                  labelText: "Team 2",
                ),
                onChanged: (value) {
                  setState(() {
                    analysisFunction = null;
                    blue2FieldValue = value;
                  });
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  filled: true,
                  labelText: "Team 3",
                ),
                onChanged: (value) {
                  setState(() {
                    analysisFunction = null;
                    blue3FieldValue = value;
                  });
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: int.tryParse(red1FieldValue) == null ||
                    int.tryParse(red2FieldValue) == null ||
                    int.tryParse(red3FieldValue) == null ||
                    int.tryParse(blue1FieldValue) == null ||
                    int.tryParse(blue2FieldValue) == null ||
                    int.tryParse(blue3FieldValue) == null
                ? null
                : () {
                    setState(() {
                      analysisFunction = ScorePredictorAnalysis(
                        blue1: int.parse(blue1FieldValue),
                        blue2: int.parse(blue2FieldValue),
                        blue3: int.parse(blue3FieldValue),
                        red1: int.parse(red1FieldValue),
                        red2: int.parse(red2FieldValue),
                        red3: int.parse(red3FieldValue),
                      );
                    });
                  },
            child: const Text("Predict"),
          ),
          const SizedBox(height: 40),
          if (analysisFunction != null)
            ScorePrediction(
              analysis: analysisFunction!,
            )
        ],
      ),
      drawer: const NavigationDrawer(),
    );
  }
}

class ScorePrediction extends AnalysisVisualization {
  const ScorePrediction({
    Key? key,
    required ScorePredictorAnalysis analysis,
  }) : super(key: key, analysisFunction: analysis);

  @override
  Widget loadedData(BuildContext context, AsyncSnapshot snapshot) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Red Alliance",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  snapshot.data["redScore"].toString(),
                  style: Theme.of(context).textTheme.headlineLarge!.merge(
                      TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer)),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Blue Alliance",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  snapshot.data["blueScore"].toString(),
                  style: Theme.of(context).textTheme.headlineLarge!.merge(
                      TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
