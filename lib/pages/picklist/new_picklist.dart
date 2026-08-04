import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/custom_field_indicator.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewPicklistPage extends StatefulWidget {
  const NewPicklistPage({super.key});

  @override
  State<NewPicklistPage> createState() => _NewPicklistPageState();
}

class _NewPicklistPageState extends State<NewPicklistPage> {
  ConfiguredPicklist? picklist;

  @override
  void initState() {
    super.initState();
    loadWeights();
  }

  Future<void> loadWeights() async {
    final weights = await getAllPicklistWeights(includeArchived: false);

    if (!mounted) return;

    setState(() {
      picklist = ConfiguredPicklist.autoUuid("", weights);
    });
  }

  @override
  Widget build(BuildContext context) {
    final picklist = this.picklist;

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Picklist"),
        actions: [
          FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    picklist != null) {
                  picklist.author = snapshot.data!.getString('username');
                }

                return IconButton(
                  onPressed: picklist == null ||
                          picklist.title.isEmpty ||
                          snapshot.connectionState != ConnectionState.done
                      ? null
                      : () async {
                          final onCreate = (ModalRoute.of(context)!
                              .settings
                              .arguments as Map<String, dynamic>)['onCreate'];

                          final scaffoldMessengerState =
                              ScaffoldMessenger.of(context);
                          final navigatorState = Navigator.of(context);

                          await addPicklist(picklist);

                          onCreate();

                          scaffoldMessengerState.showSnackBar(const SnackBar(
                            content: Text("Created picklist"),
                            behavior: SnackBarBehavior.floating,
                          ));

                          navigatorState.pop();
                        },
                  icon: const Icon(Icons.check),
                  tooltip: "Create",
                  color: Colors.green,
                );
              })
        ],
      ),
      body: picklist == null
          ? const LinearProgressIndicator()
          : ScrollablePageBody(padding: EdgeInsets.zero, children: [
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
