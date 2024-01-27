import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';
import 'package:skeletons/skeletons.dart';

class EditScoutSchedulePage extends StatefulWidget {
  const EditScoutSchedulePage({super.key});

  @override
  State<EditScoutSchedulePage> createState() => _EditScoutSchedulePageState();
}

class _EditScoutSchedulePageState extends State<EditScoutSchedulePage> {
  ScoutSchedule? scoutSchedule;

  Future<void> fetchData() async {
    final scoutSchedule = await lovatAPI.getScouterSchedule();
    debugPrint(scoutSchedule.shifts.toString());
    setState(() {
      this.scoutSchedule = scoutSchedule;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (scoutSchedule == null) {
      body = SkeletonListView(
        itemBuilder: (context, index) => SkeletonListTile(),
      );
    } else {
      body = ListView.builder(
        itemBuilder: (context, index) {
          final shift = scoutSchedule!.shifts[index];
          return ListTile(
            title: Text("${shift.start} to ${shift.end}"),
            subtitle: Text(shift.allScoutsList),
          );
        },
        itemCount: scoutSchedule!.shifts.length,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Scout Schedule"),
      ),
      body: body,
    );
  }
}
