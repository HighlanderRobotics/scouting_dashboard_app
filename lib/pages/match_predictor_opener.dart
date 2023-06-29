import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class MatchPredictorOpenerPage extends StatefulWidget {
  const MatchPredictorOpenerPage({super.key});

  @override
  State<MatchPredictorOpenerPage> createState() =>
      _MatchPredictorOpenerPageState();
}

class _MatchPredictorOpenerPageState extends State<MatchPredictorOpenerPage> {
  String red1FieldValue = "";
  String red2FieldValue = "";
  String red3FieldValue = "";
  String blue1FieldValue = "";
  String blue2FieldValue = "";
  String blue3FieldValue = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hypothetical Match Prediction")),
      body: ScrollablePageBody(
          children: [
        const Text("Red Alliance"),
        TextField(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(filled: true, label: Text("Team 1")),
          onChanged: (value) => setState(() {
            red1FieldValue = value;
          }),
        ),
        TextField(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(filled: true, label: Text("Team 2")),
          onChanged: (value) => setState(() {
            red2FieldValue = value;
          }),
        ),
        TextField(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(filled: true, label: Text("Team 3")),
          onChanged: (value) => setState(() {
            red3FieldValue = value;
          }),
        ),
        const SizedBox(height: 10),
        const Text("Blue Alliance"),
        TextField(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(filled: true, label: Text("Team 1")),
          onChanged: (value) => setState(() {
            blue1FieldValue = value;
          }),
        ),
        TextField(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(filled: true, label: Text("Team 2")),
          onChanged: (value) => setState(() {
            blue2FieldValue = value;
          }),
        ),
        TextField(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(filled: true, label: Text("Team 3")),
          onChanged: (value) => setState(() {
            blue3FieldValue = value;
          }),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: !isValid()
              ? null
              : () {
                  Navigator.of(context)
                      .pushNamed("/match_predictor", arguments: {
                    'red1': red1FieldValue,
                    'red2': red2FieldValue,
                    'red3': red3FieldValue,
                    'blue1': blue1FieldValue,
                    'blue2': blue2FieldValue,
                    'blue3': blue3FieldValue,
                  });
                },
          child: const Text("View"),
        )
      ].withSpaceBetween(height: 10)),
      drawer: const GlobalNavigationDrawer(),
    );
  }

  bool isValid() {
    if ([
      red1FieldValue,
      red2FieldValue,
      red3FieldValue,
      blue1FieldValue,
      blue2FieldValue,
      blue3FieldValue,
    ].any((element) => int.tryParse(element) == null)) return false;

    return true;
  }
}
