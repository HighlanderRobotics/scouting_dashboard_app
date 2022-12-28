import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/analysis_functions/score_predictor_analysis.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';

import '../reusable/analysis_visualization.dart';

class ScorePredictor extends StatefulWidget {
  const ScorePredictor({super.key});

  @override
  State<ScorePredictor> createState() => _ScorePredictorState();
}

class _ScorePredictorState extends State<ScorePredictor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Score Predictor")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Red Alliance"),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      labelText: "Team 1",
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      labelText: "Team 2",
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      labelText: "Team 3",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Blue Alliance"),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      labelText: "Team 1",
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      labelText: "Team 2",
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      labelText: "Team 3",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {},
                child: const Text("Predict"),
              ),
              const SizedBox(height: 40),
              ScorePrediction(
                analysis: ScorePredictorAnalysis(
                    blue1: 1, blue2: 2, blue3: 3, red1: 4, red2: 5, red3: 6),
              )
            ],
          ),
        ),
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
