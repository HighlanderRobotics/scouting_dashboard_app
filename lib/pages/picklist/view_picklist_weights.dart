import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class ViewPicklistWeightsPage extends StatelessWidget {
  const ViewPicklistWeightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    ConfiguredPicklist picklist = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['picklist'];

    return Scaffold(
      appBar: AppBar(title: Text("${picklist.title} - Weights")),
      body: ScrollablePageBody(
          children: picklist.weights
              .map((weight) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(weight.localizedName),
                      Slider(
                          value: weight.value, onChanged: null, min: 0, max: 1)
                    ],
                  ))
              .toList()),
    );
  }
}
