import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class NewPicklistPage extends StatefulWidget {
  const NewPicklistPage({super.key});

  @override
  State<NewPicklistPage> createState() => _NewPicklistPageState();
}

class _NewPicklistPageState extends State<NewPicklistPage> {
  ConfiguredPicklist picklist = ConfiguredPicklist.defaultWeights("");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Picklist"),
        actions: [
          IconButton(
            onPressed: picklist.title.isEmpty
                ? null
                : () async {
                    await addPicklist(picklist);

                    (ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>)['onCreate']();

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Created picklist"),
                      behavior: SnackBarBehavior.floating,
                    ));

                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.check),
            color: Colors.green,
          )
        ],
      ),
      body: ScrollablePageBody(padding: EdgeInsets.zero, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
          child: TextField(
            decoration: const InputDecoration(
              filled: true,
              label: Text("Title"),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => setState(() {
              picklist.title = value;
            }),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: picklistWeights
              .map((weight) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 15),
                        child: Text(weight.localizedName),
                      ),
                      Slider(
                          min: 0,
                          max: 1,
                          divisions: 8,
                          value: picklist.weights
                              .firstWhere((e) => e.path == weight.path)
                              .value,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              picklist.weights
                                  .firstWhere((e) => e.path == weight.path)
                                  .value = value;
                            });
                          }),
                      const SizedBox(height: 14),
                    ],
                  ))
              .toList(),
        )
      ]),
    );
  }
}
