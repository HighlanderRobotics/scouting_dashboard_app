import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class PicklistsPage extends StatefulWidget {
  const PicklistsPage({super.key});

  @override
  State<PicklistsPage> createState() => _PicklistsPageState();
}

class _PicklistsPageState extends State<PicklistsPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getPicklists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Picklists"),
              ),
              body: const PageBody(
                padding: EdgeInsets.zero,
                child: LinearProgressIndicator(),
              ),
              drawer: const GlobalNavigationDrawer(),
            );
          }

          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            List<ConfiguredPicklist> picklists = snapshot.data!;

            return Scaffold(
              appBar: AppBar(
                title: const Text("Picklists"),
              ),
              body: ScrollablePageBody(
                padding: EdgeInsets.zero,
                children: picklists
                    .map((picklist) => Column(
                          children: [
                            Dismissible(
                              onUpdate: (details) {
                                if ((details.reached &&
                                        !details.previousReached) ||
                                    (!details.reached &&
                                        details.previousReached)) {
                                  HapticFeedback.lightImpact();
                                }
                              },
                              key: GlobalKey(),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red[900],
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: const [
                                      Icon(Icons.delete),
                                      SizedBox(width: 30),
                                    ],
                                  ),
                                ),
                              ),
                              child: ListTile(
                                title: Text(picklist.title),
                                trailing: Icon(
                                  Icons.arrow_right,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                onTap: () {
                                  Navigator.of(context).pushNamed('/picklist',
                                      arguments: <String, dynamic>{
                                        'picklist': picklist,
                                        'onChanged': () async {
                                          await setPicklists(picklists);

                                          setState(() {});
                                        }
                                      });
                                },
                              ),
                              onDismissed: (direction) async {
                                picklists.remove(picklist);

                                await setPicklists(picklists);
                              },
                            ),
                            Divider(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              height: 0,
                            ),
                          ],
                        ))
                    .toList(),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed('/new_picklist', arguments: <String, dynamic>{
                    'onCreate': () {
                      setState(() {});
                    }
                  });
                },
                child: const Icon(Icons.add),
              ),
              drawer: const GlobalNavigationDrawer(),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text("Picklists"),
            ),
            body: const PageBody(
              padding: EdgeInsets.zero,
              child: Center(child: Icon(Icons.sentiment_dissatisfied_outlined)),
            ),
            drawer: const GlobalNavigationDrawer(),
          );
        });
  }
}
