import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/scout_name_selector.dart';

class NewScoutShift extends StatefulWidget {
  const NewScoutShift({super.key});

  @override
  State<NewScoutShift> createState() => _NewScoutShiftState();
}

class _NewScoutShiftState extends State<NewScoutShift> {
  ScoutSchedule? schedule;

  TextEditingController? startController;
  TextEditingController? endController;

  ScoutingShift? shift;

  String? getError() {
    ScoutSchedule proposedSchedule = schedule!.copy();
    proposedSchedule.shifts.add(shift!);

    return proposedSchedule.validate();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> routeArguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    schedule ??= routeArguments['schedule'];
    shift ??= ScoutingShift(start: 0, end: 0, scouts: ["", "", "", "", "", ""]);

    startController ??= TextEditingController(text: shift!.start.toString());
    endController ??= TextEditingController(text: shift!.end.toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Shift"),
        actions: [
          IconButton(
            onPressed: getError() == null
                ? () {
                    routeArguments['setParentState'](() {
                      schedule!.shifts.add(shift!);
                      Navigator.of(context).pop();

                      const SnackBar snackBar = SnackBar(
                        content: Text("Created shift. Tap the check to save."),
                        behavior: SnackBarBehavior.floating,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    });
                  }
                : null,
            icon: const Icon(Icons.check),
            color: Colors.green,
          )
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    if (int.tryParse(value) == null) return;

                    setState(() {
                      shift!.start = int.parse(value);
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
                    if (int.tryParse(value) == null) return;

                    setState(() {
                      shift!.end = int.parse(value);
                    });
                  },
                ),
                if (getError() != null) const SizedBox(height: 10),
                if (getError() != null)
                  Text(getError()!
                      .replaceAll(RegExp('\\. *'), " if this is added.")),
                const SizedBox(height: 20),
                Text(
                  "Scouts",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ScoutNameSelector(
                  label: "Scout 1",
                  onChange: (value) {
                    setState(() {
                      shift!.scouts[0] = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ScoutNameSelector(
                  label: "Scout 2",
                  onChange: (value) {
                    setState(() {
                      shift!.scouts[1] = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ScoutNameSelector(
                  label: "Scout 3",
                  onChange: (value) {
                    setState(() {
                      shift!.scouts[2] = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ScoutNameSelector(
                  label: "Scout 4",
                  onChange: (value) {
                    setState(() {
                      shift!.scouts[3] = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ScoutNameSelector(
                  label: "Scout 5",
                  onChange: (value) {
                    setState(() {
                      shift!.scouts[4] = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ScoutNameSelector(
                  label: "Scout 6",
                  onChange: (value) {
                    setState(() {
                      shift!.scouts[5] = value;
                    });
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
