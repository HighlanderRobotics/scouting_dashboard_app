import 'package:flutter/material.dart';

import '../reusable/navigation_drawer.dart';

class TeamLookup extends StatefulWidget {
  const TeamLookup({super.key});

  @override
  State<TeamLookup> createState() => _TeamLookupState();
}

class _TeamLookupState extends State<TeamLookup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Team Lookup")),
      body: const Text("Team Lookup"),
      drawer: const NavigationDrawer(),
    );
  }
}
