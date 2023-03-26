import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/team_auto_paths.dart';

class AutoPathSelectorPage extends StatefulWidget {
  const AutoPathSelectorPage({super.key});

  @override
  State<AutoPathSelectorPage> createState() => _AutoPathSelectorPageState();
}

class _AutoPathSelectorPageState extends State<AutoPathSelectorPage> {
  AutoPath? selectedPath;

  bool initialized = false;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    String team = routeArgs['team'];
    List<AutoPath> autoPaths = routeArgs['autoPaths'];
    dynamic Function(AutoPath) callback = routeArgs['onSubmit'];
    AutoPath? initialSelection = routeArgs['currentPath'];

    if (initialized == false) {
      setState(() {
        selectedPath = initialSelection;
        initialized = true;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("$team's Auto Paths"),
        actions: [
          IconButton(
            onPressed: selectedPath == null
                ? null
                : () {
                    callback(selectedPath!);
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.check),
            color: Colors.green,
          ),
        ],
      ),
      body: ScrollablePageBody(children: [
        TeamAutoPaths(
          autoPaths: autoPaths,
          initialSelection: initialSelection,
          onChanged: (val) => {
            setState(() {
              selectedPath = val;
            })
          },
        ),
      ]),
    );
  }
}
