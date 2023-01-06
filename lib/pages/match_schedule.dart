import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/role_exclusive.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

import '../reusable/navigation_drawer.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Schedule"),
        actions: [
          RoleExclusive(
            role: "scouting_lead",
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/edit_scout_schedule");
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
          RoleExclusive(
            role: "scouting_lead",
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/scout_schedule_qr");
              },
              icon: const Icon(Icons.qr_code),
            ),
          ),
        ],
      ),
      body: const ScrollablePageBody(children: [Text("Schedule")]),
      drawer: const NavigationDrawer(),
    );
  }
}
