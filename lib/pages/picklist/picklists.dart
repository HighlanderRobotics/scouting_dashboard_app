import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

import 'package:http/http.dart' as http;

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

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text("Picklists"),
                  bottom: const TabBar(tabs: [
                    Text("Mine"),
                    Text("Shared"),
                  ]),
                ),
                body: TabBarView(
                  children: [
                    myPicklists(picklists, context),
                    SharedPicklists(),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/new_picklist',
                        arguments: <String, dynamic>{
                          'onCreate': () {
                            setState(() {});
                          }
                        });
                  },
                  child: const Icon(Icons.add),
                ),
                drawer: const GlobalNavigationDrawer(),
              ),
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

  ScrollablePageBody myPicklists(
      List<ConfiguredPicklist> picklists, BuildContext context) {
    return ScrollablePageBody(
      padding: EdgeInsets.zero,
      children: picklists
          .map((picklist) => Column(
                children: [
                  Dismissible(
                    onUpdate: (details) {
                      if ((details.reached && !details.previousReached) ||
                          (!details.reached && details.previousReached)) {
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
                        color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    height: 0,
                  ),
                ],
              ))
          .toList(),
    );
  }
}

Future<List<ConfiguredPicklist>> getSharedPicklists() async {
  String authority = (await getServerAuthority())!;

  final response =
      await http.get(Uri.http(authority, '/API/manager/getPicklists'));

  if (response.statusCode != 200) {
    throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
  }

  List<dynamic> parsedResponse = jsonDecode(response.body);

  return parsedResponse
      .map((e) => ConfiguredPicklist.fromServerJSON(jsonEncode(e)))
      .toList();
}

class SharedPicklists extends StatelessWidget {
  const SharedPicklists({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getSharedPicklists(),
      builder: (BuildContext context,
          AsyncSnapshot<List<ConfiguredPicklist>> snapshot) {
        if (snapshot.hasError) {
          return Text("Error getting picklists: ${snapshot.error}");
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return Column(children: const [LinearProgressIndicator()]);
        }

        return ScrollablePageBody(
          padding: EdgeInsets.zero,
          children: snapshot.data!
              .map((picklist) => Column(
                    children: [
                      Dismissible(
                        onUpdate: (details) {
                          if ((details.reached && !details.previousReached) ||
                              (!details.reached && details.previousReached)) {
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              "/shared_picklist",
                              arguments: {
                                'picklist': picklist,
                              },
                            );
                          },
                        ),
                        onDismissed: (direction) async {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Deleting..."),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            deleteSharedPicklist(picklist.id);

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Successfully deleted picklist "${picklist.title}"'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (error) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString(),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer),
                                ),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      Divider(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        height: 0,
                      ),
                    ],
                  ))
              .toList(),
        );
      },
    );
  }
}

Future<void> deleteSharedPicklist(String uuid) async {
  String authority = (await getServerAuthority())!;

  final response =
      await http.get(Uri.http(authority, '/API/manager/deletePicklist', {
    'uuid': uuid,
  }));

  if (response.statusCode != 200) {
    throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
  }
}
