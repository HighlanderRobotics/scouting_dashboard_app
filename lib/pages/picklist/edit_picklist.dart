import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class EditPicklistPage extends StatefulWidget {
  const EditPicklistPage({super.key});

  @override
  State<EditPicklistPage> createState() => _EditPicklistPageState();
}

class _EditPicklistPageState extends State<EditPicklistPage> {
  TextEditingController titleFieldController = TextEditingController();
  bool initialized = false;

  @override
  Widget build(BuildContext context) {
    ConfiguredPicklist picklist = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['picklist'];

    Future<void> Function() onChanged = (ModalRoute.of(context)!
        .settings
        .arguments as Map<String, dynamic>)['onChanged'];

    if (!initialized) titleFieldController.text = picklist.title;

    initialized = true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Editing "${picklist.title}"'),
        actions: [
          IconButton(
            onPressed: () async {
              await onChanged();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check),
            color: Colors.green,
          ),
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
            controller: titleFieldController,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: picklist.weights
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
                          value: weight.value,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              weight.value = value;
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
