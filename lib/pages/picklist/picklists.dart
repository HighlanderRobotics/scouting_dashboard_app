import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PicklistsPage extends StatefulWidget {
  const PicklistsPage({super.key});

  @override
  State<PicklistsPage> createState() => _PicklistsPageState();
}

class _PicklistsPageState extends State<PicklistsPage> {
  int selectedTab = 0;
  dynamic Function()? onNewPicklist;

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
            bottom: const TabBar(
              labelPadding: EdgeInsets.symmetric(vertical: 11),
              tabs: [
                Text("Mine"),
                Text("Shared"),
                Text("Mutable"),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              MyPicklists(
                onCallFrontAvailable: (callFront) => onNewPicklist = callFront,
              ),
              const SharedPicklists(),
              const MutablePicklists(),
            ],
          ),
          floatingActionButton: selectedTab == 0 &&
                  !DefaultTabController.of(context).indexIsChanging
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/new_picklist',
                        arguments: <String, dynamic>{
                          'onCreate': () {
                            if (onNewPicklist != null) {
                              onNewPicklist!();
                            }
                          }
                        });
                  },
                  tooltip: "New picklist",
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
    required this.onCallFrontAvailable,
  });

  final Function(dynamic Function()) onCallFrontAvailable;

  @override
  State<MyPicklists> createState() => _MyPicklistsState();
}

class _MyPicklistsState extends State<MyPicklists> {
  @override
  void initState() {
    super.initState();

    widget.onCallFrontAvailable(() {
      setState(() {});
    });
  }

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
            return const PageBody(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
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
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
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

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted "${picklist.title}"'),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                    label: "Undo",
                                    onPressed: () async {
                                      try {
                                        picklists.add(picklist);
                                        await setPicklists(picklists);
                                        setState(() {});
                                      } catch (error) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                                    }),
                              ),
                            );
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

class SharedPicklists extends StatefulWidget {
  const SharedPicklists({
    super.key,
  });

  @override
  State<SharedPicklists> createState() => _SharedPicklistsState();
}

class _SharedPicklistsState extends State<SharedPicklists> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConfiguredPicklistMeta>>(
      future: lovatAPI.getSharedPicklists(),
      builder: (BuildContext context,
          AsyncSnapshot<List<ConfiguredPicklistMeta>> snapshot) {
        if (snapshot.hasError) {
          return FriendlyErrorView(errorMessage: snapshot.error.toString());
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Column(children: [LinearProgressIndicator()]);
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
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.delete),
                                SizedBox(width: 30),
                              ],
                            ),
                          ),
                        ),
                        child: ListTile(
                          title: Text(picklist.title),
                          subtitle: picklist.author == null
                              ? null
                              : Text(picklist.author!),
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

                            await lovatAPI
                                .deleteSharedPicklistById(picklist.id);

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Successfully deleted picklist "${picklist.title}"',
                                ),
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

class MutablePicklists extends StatefulWidget {
  const MutablePicklists({super.key});

  @override
  State<MutablePicklists> createState() => _MutablePicklistsState();
}

class _MutablePicklistsState extends State<MutablePicklists> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return realListsWithPermission();
  }

  FutureBuilder<List<MutablePicklistMeta>> realListsWithPermission() {
    return FutureBuilder<List<MutablePicklistMeta>>(
        future: lovatAPI.getMutablePicklists(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return FriendlyErrorView(errorMessage: snapshot.error.toString());
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return const PageBody(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  LinearProgressIndicator(),
                ],
              ),
            );
          }

          List<MutablePicklistMeta> picklistsMeta = snapshot.data!;

          return ScrollablePageBody(
            padding: EdgeInsets.zero,
            children: picklistsMeta
                .map((picklistMeta) => Column(
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
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete),
                                  SizedBox(width: 30),
                                ],
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(picklistMeta.name),
                            subtitle: picklistMeta.author == null
                                ? null
                                : Text(picklistMeta.author!),
                            trailing: Icon(
                              Icons.arrow_right,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onTap: () async {
                              setState(() {
                                loading = true;
                              });

                              try {
                                Navigator.of(context).pushNamed(
                                    '/mutable_picklist',
                                    arguments: <String, dynamic>{
                                      'picklist':
                                          await picklistMeta.getPicklist(),
                                      'callback': () => setState(() {}),
                                    });
                              } catch (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $error",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer)),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .errorContainer,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } finally {
                                setState(() {
                                  loading = false;
                                });
                              }
                            },
                          ),
                          onDismissed: (direction) async {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Deleting..."),
                              behavior: SnackBarBehavior.floating,
                            ));

                            try {
                              await picklistMeta.delete();

                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("Successfully deleted"),
                                behavior: SnackBarBehavior.floating,
                              ));
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
