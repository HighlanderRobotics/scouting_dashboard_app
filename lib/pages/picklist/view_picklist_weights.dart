import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class ViewPicklistWeightsPage extends StatefulWidget {
  const ViewPicklistWeightsPage({super.key, required this.picklistMeta});

  final ConfiguredPicklistMeta picklistMeta;

  @override
  State<ViewPicklistWeightsPage> createState() =>
      _ViewPicklistWeightsPageState();
}

class _ViewPicklistWeightsPageState extends State<ViewPicklistWeightsPage> {
  ConfiguredPicklist? picklist;
  String? error;

  Future<void> fetchPicklist() async {
    setState(() {
      error = null;
    });

    try {
      final fetchedPicklist = await widget.picklistMeta.getPicklist();

      setState(() {
        picklist = fetchedPicklist;
      });
    } catch (error) {
      setState(() {
        this.error = error.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPicklist();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (picklist == null && error == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = FriendlyErrorView(
        errorMessage: error,
        onRetry: () async {
          await fetchPicklist();
        },
      );
    } else {
      body = ScrollablePageBody(
          children: picklist!.weights
              .map((weight) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(weight.localizedName),
                      Slider(
                          value: weight.value, onChanged: null, min: 0, max: 1)
                    ],
                  ))
              .toList());
    }

    return Scaffold(
      appBar: AppBar(title: Text("${widget.picklistMeta.title} - Weights")),
      body: body,
    );
  }
}
