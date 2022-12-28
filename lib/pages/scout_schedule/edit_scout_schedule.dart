import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';

class EditScoutSchedule extends StatefulWidget {
  const EditScoutSchedule({super.key});

  @override
  State<EditScoutSchedule> createState() => _EditScoutScheduleState();
}

class _EditScoutScheduleState extends State<EditScoutSchedule> {
  Future<void> setOldSchedule() async {
    final oldSchedule = await getScoutSchedule();

    setState(() {
      schedule = oldSchedule;
    });
  }

  @override
  void initState() {
    super.initState();

    setOldSchedule();
  }

  ScoutSchedule? schedule;

  @override
  Widget build(BuildContext context) {
    return schedule == null
        ? Scaffold(
            appBar: AppBar(title: const Text("Edit Scout Schedule")),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            appBar: AppBar(title: const Text("Edit Scout Schedule")),
            body: Text("loaded"),
          );
  }
}
