import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class MatchSuggestionsOpenerPage extends StatefulWidget {
  const MatchSuggestionsOpenerPage({super.key});

  @override
  State<MatchSuggestionsOpenerPage> createState() =>
      _MatchSuggestionsOpenerPageState();
}

class _MatchSuggestionsOpenerPageState
    extends State<MatchSuggestionsOpenerPage> {
  String red1FieldValue = "";
  String red2FieldValue = "";
  String red3FieldValue = "";
  String blue1FieldValue = "";
  String blue2FieldValue = "";
  String blue3FieldValue = "";
  MatchType matchType = MatchType.qualifier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hypothetical Match Suggestions")),
      body: ScrollablePageBody(
          children: [
        DropdownSearch<MatchType>(
          items: MatchType.values,
          itemAsString: (item) => item.localizedDescriptionSingular,
          selectedItem: matchType,
          onChanged: (value) => setState(() {
            matchType = value!;
          }),
          dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
            filled: true,
            label: Text("Match Type"),
          )),
        ),
        const SizedBox(height: 10),
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
                      .pushNamed("/match_suggestions", arguments: {
                    'teams': <String, int>{
                      'red1': int.parse(red1FieldValue),
                      'red2': int.parse(red2FieldValue),
                      'red3': int.parse(red3FieldValue),
                      'blue1': int.parse(blue1FieldValue),
                      'blue2': int.parse(blue2FieldValue),
                      'blue3': int.parse(blue3FieldValue),
                    },
                    'matchType': matchType,
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
