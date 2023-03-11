import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/analysis_functions/score_predictor_analysis.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
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
      drawer: const GlobalNavigationDrawer(),
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
    if ((snapshot.data as Map<String, dynamic>).containsKey("blueWinning")) {
      return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(7)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            Flexible(
              fit: FlexFit.tight,
              flex: ((snapshot.data['redWinning'] as num) * 100).round(),
              child: Container(
                decoration: BoxDecoration(color: redAlliance),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Red alliance"),
                        Text(
                          "${((snapshot.data['redWinning'] as num) * 100).round()}%",
                          style: Theme.of(context).textTheme.titleLarge,
                        )
                      ]),
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              flex: ((snapshot.data['blueWinning'] as num) * 100).round(),
              child: Container(
                decoration: BoxDecoration(color: blueAlliance),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Blue alliance"),
                        Text(
                          "${((snapshot.data['blueWinning'] as num) * 100).round()}%",
                          style: Theme.of(context).textTheme.titleLarge,
                        )
                      ]),
                ),
              ),
            ),
          ]));
    } else {
      return const Text("Not enough data for prediction.");
    }
  }
}
