import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/reusable/scout_name_selector.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class EditScoutShiftPage extends StatefulWidget {
  const EditScoutShiftPage({super.key});

  @override
  State<EditScoutShiftPage> createState() => _EditScoutShiftPageState();
}

class _EditScoutShiftPageState extends State<EditScoutShiftPage> {
  ScoutingShift? shift;

  TextEditingController? startController;
  TextEditingController? endController;

  TextEditingController? scout1Controller;
  TextEditingController? scout2Controller;
  TextEditingController? scout3Controller;
  TextEditingController? scout4Controller;
  TextEditingController? scout5Controller;
  TextEditingController? scout6Controller;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> routeArguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    shift ??= routeArguments['shift'];

    startController ??= TextEditingController(text: shift!.start.toString());
    endController ??= TextEditingController(text: shift!.end.toString());

    scout1Controller ??= TextEditingController(text: shift!.scouts[0]);
    scout2Controller ??= TextEditingController(text: shift!.scouts[1]);
    scout3Controller ??= TextEditingController(text: shift!.scouts[2]);
    scout4Controller ??= TextEditingController(text: shift!.scouts[3]);
    scout5Controller ??= TextEditingController(text: shift!.scouts[4]);
    scout6Controller ??= TextEditingController(text: shift!.scouts[5]);

    return Scaffold(
      appBar: AppBar(title: const Text("Editing Shift")),
      body: ScrollablePageBody(
        children: [
          Text(
            "Matches",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: startController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              filled: true,
              label: Text("Start"),
            ),
            onChanged: (value) {
              setState(() {
                routeArguments['setParentState'](() {
                  if (int.tryParse(value) != null) {
                    shift!.start = int.parse(value);
                  }
                });
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: endController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              filled: true,
              label: Text("End"),
            ),
            onChanged: (value) {
              setState(() {
                routeArguments['setParentState'](() {
                  if (int.tryParse(value) != null) {
                    shift!.end = int.parse(value);
                  }
                });
              });
            },
          ),
          const SizedBox(height: 20),
          Text(
            "Scouts",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          ScoutNameSelector(
            label: "Scout 1",
            onChange: (value) {
              routeArguments['setParentState'](() {
                shift!.scouts[0] = value;
              });
            },
            initialValue: shift!.scouts[0],
          ),
          const SizedBox(height: 10),
          ScoutNameSelector(
            label: "Scout 2",
            onChange: (value) {
              routeArguments['setParentState'](() {
                shift!.scouts[1] = value;
              });
            },
            initialValue: shift!.scouts[1],
          ),
          const SizedBox(height: 10),
          ScoutNameSelector(
            label: "Scout 3",
            onChange: (value) {
              routeArguments['setParentState'](() {
                shift!.scouts[2] = value;
              });
            },
            initialValue: shift!.scouts[2],
          ),
          const SizedBox(height: 10),
          ScoutNameSelector(
            label: "Scout 4",
            onChange: (value) {
              routeArguments['setParentState'](() {
                shift!.scouts[3] = value;
              });
            },
            initialValue: shift!.scouts[3],
          ),
          const SizedBox(height: 10),
          ScoutNameSelector(
            label: "Scout 5",
            onChange: (value) {
              routeArguments['setParentState'](() {
                shift!.scouts[4] = value;
              });
            },
            initialValue: shift!.scouts[4],
          ),
          const SizedBox(height: 10),
          ScoutNameSelector(
            label: "Scout 6",
            onChange: (value) {
              routeArguments['setParentState'](() {
                shift!.scouts[5] = value;
              });
            },
            initialValue: shift!.scouts[5],
          )
        ],
      ),
    );
  }
}
