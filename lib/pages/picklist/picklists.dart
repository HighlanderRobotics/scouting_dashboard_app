import 'dart:convert';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/role_exclusive.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

import 'package:http/http.dart' as http;

class PicklistsPage extends StatefulWidget {
  const PicklistsPage({super.key});

  @override
  State<PicklistsPage> createState() => _PicklistsPageState();
}

class _PicklistsPageState extends State<PicklistsPage> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(builder: (context) {
        DefaultTabController.of(context).addListener(
          () {
            setState(() {
              selectedTab = DefaultTabController.of(context).index;
            });
          },
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text("Picklists"),
            bottom: const TabBar(tabs: [
              Text("Mine"),
              Text("Shared"),
              Text("Mutable"),
            ]),
          ),
          body: const TabBarView(
            children: [
              MyPicklists(),
              SharedPicklists(),
              MutablePicklists(),
            ],
          ),
          floatingActionButton: selectedTab == 0 &&
                  !DefaultTabController.of(context).indexIsChanging
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/new_picklist',
                        arguments: <String, dynamic>{
                          'onCreate': () {
                            setState(() {});
                          }
                        });
                  },
                  child: const Icon(Icons.add),
                )
              : null,
          drawer: const GlobalNavigationDrawer(),
        );
      }),
    );
  }
}

class MyPicklists extends StatefulWidget {
  const MyPicklists({
    super.key,
  });

  @override
  State<MyPicklists> createState() => _MyPicklistsState();
}

class _MyPicklistsState extends State<MyPicklists> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getPicklists(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return PageBody(
              child: Text(
                  "Encountered an error while fetching picklists:${snapshot.error}"),
            );
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return PageBody(
              padding: EdgeInsets.zero,
              child: Column(
                children: const [
                  LinearProgressIndicator(),
                ],
              ),
            );
          }

          List<ConfiguredPicklist> picklists = snapshot.data!;

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
        });
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

Future<List<MutablePicklist>> getMutablePicklists() async {
  final authority = (await getServerAuthority())!;

  final response =
      await http.get(Uri.http(authority, '/API/manager/getMutablePicklists'));

  if (response.statusCode != 200) {
    throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
  }

  return (jsonDecode(response.body) as List<dynamic>)
      .map((listMap) => MutablePicklist(
            uuid: listMap['uuid'],
            name: listMap['name'],
            teams: listMap['teams'].cast<int>(),
          ))
      .toList();
}

class MutablePicklists extends StatefulWidget {
  const MutablePicklists({super.key});

  @override
  State<MutablePicklists> createState() => _MutablePicklistsState();
}

class _MutablePicklistsState extends State<MutablePicklists> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RoleExclusive(
          roles: ["analyst"],
          child: Text("You don't have permission to access this."),
        ),
        RoleExclusive(
          roles: const [
            "8033_analyst",
            "8033_scouting_lead",
          ],
          child: realListsWithPermission(),
        ),
      ],
    );
  }

  FutureBuilder<List<MutablePicklist>> realListsWithPermission() {
    return FutureBuilder(
        future: getMutablePicklists(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return PageBody(
              child: Text(
                  "Encountered an error while fetching picklists: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return PageBody(
              padding: EdgeInsets.zero,
              child: Column(
                children: const [
                  LinearProgressIndicator(),
                ],
              ),
            );
          }

          List<MutablePicklist> picklists = snapshot.data!;

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
                            title: Text(picklist.name),
                            trailing: Icon(
                              Icons.arrow_right,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                  '/mutable_picklist',
                                  arguments: <String, dynamic>{
                                    'picklist': picklist,
                                    'callback': () => setState(() {}),
                                  });
                            },
                          ),
                          onDismissed: (direction) async {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Deleting..."),
                              behavior: SnackBarBehavior.floating,
                            ));

                            try {
                              await picklist.delete();
                            } catch (error) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                  "Error deleting: $error",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                              ));

                              return;
                            }

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Successfully deleted"),
                              behavior: SnackBarBehavior.floating,
                            ));
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
        });
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
