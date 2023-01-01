import 'package:flutter/material.dart';

import '../reusable/navigation_drawer.dart';

class TeamLookup extends StatefulWidget {
  const TeamLookup({super.key});

  @override
  State<TeamLookup> createState() => _TeamLookupState();
}

class _TeamLookupState extends State<TeamLookup> {
  String teamFieldValue = "";
  int? teamNumberForAnalysis;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Team Lookup")),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("Team #"),
                ),
                onChanged: (value) {
                  setState(() {
                    teamFieldValue = value;
                    if (int.tryParse(value) != null) {
                      teamNumberForAnalysis = int.parse(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Total",
                          style: Theme.of(context).textTheme.titleLarge!.merge(
                                TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                        ),
                      ),
                      Row(children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF6F7200),
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Column(
                              children: [
                                Text(
                                  "41",
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  "Avg score",
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      ]),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.navigate_next,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ]),
      drawer: const NavigationDrawer(),
    );
  }
}
