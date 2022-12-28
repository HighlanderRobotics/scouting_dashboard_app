import 'package:flutter/material.dart';

import '../reusable/navigation_drawer.dart';

class TeamLookupDetails extends StatefulWidget {
  const TeamLookupDetails({super.key});

  @override
  State<TeamLookupDetails> createState() => _TeamLookupDetailsState();
}

class _TeamLookupDetailsState extends State<TeamLookupDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Team Lookup Details")),
      body: const Text("Team lookup details"),
      drawer: const NavigationDrawer(),
    );
  }
}
