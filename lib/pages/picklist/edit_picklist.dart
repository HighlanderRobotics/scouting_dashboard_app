import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/custom_field_indicator.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class EditPicklistPage extends StatefulWidget {
  const EditPicklistPage({super.key});

  @override
  State<EditPicklistPage> createState() => _EditPicklistPageState();
}

class _EditPicklistPageState extends State<EditPicklistPage> {
  TextEditingController titleFieldController = TextEditingController();
  bool initialized = false;

  /// Appends any available weight (archived custom fields included, so
  /// existing weights on them can still be zeroed) that the picklist doesn't
  /// have yet, at value 0.
  Future<void> mergeMissingWeights(ConfiguredPicklist picklist) async {
    final allWeights = await getAllPicklistWeights();

    if (!mounted) return;

    setState(() {
      for (final weight in allWeights) {
        if (!picklist.weights.any((e) => e.path == weight.path)) {
          picklist.weights.add(weight);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ConfiguredPicklist picklist = (ModalRoute.of(context)!.settings.arguments
        as Map<String, dynamic>)['picklist'];

    Future<void> Function() onChanged = (ModalRoute.of(context)!
        .settings
        .arguments as Map<String, dynamic>)['onChanged'];

    if (!initialized) {
      titleFieldController.text = picklist.title;
      mergeMissingWeights(picklist);
    }

    initialized = true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Editing "${picklist.title}"'),
        actions: [
          IconButton(
            onPressed: () async {
              final navigatorState = Navigator.of(context);
              await onChanged();
              navigatorState.pop();
            },
            icon: const Icon(Icons.check),
            tooltip: "Save changes",
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
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                weight.localizedName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (weight.isCustom ||
                                weight.path.startsWith('cf_')) ...[
                              const SizedBox(width: 8),
                              const CustomFieldIndicator(),
                            ],
                          ],
                        ),
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
