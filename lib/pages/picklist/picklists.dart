import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/mutable/get_mutable_picklists.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/shared/delete_shared_picklist.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/shared/get_shared_picklists.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';

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
  List<ConfiguredPicklist>? picklists;
  String? error;

  @override
  void initState() {
    super.initState();

    widget.onCallFrontAvailable(() {
      setState(() {});
    });

    _loadPicklists();
  }

  Future<void> _loadPicklists() async {
    try {
      final data = await getPicklists();
      setState(() {
        picklists = data;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null && picklists == null) {
      return PageBody(
        child: Text("Encountered an error while fetching picklists:$error"),
      );
    }

    if (picklists == null) {
      return const PageBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            LinearProgressIndicator(),
          ],
        ),
      );
    }

    return ScrollablePageBody(
      padding: EdgeInsets.zero,
      children: picklists!
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
                                await setPicklists(picklists!);

                                setState(() {});
                              }
                            });
                      },
                    ),
                    onDismissed: (direction) async {
                      final scaffoldMessengerState =
                          ScaffoldMessenger.of(context);
                      final themeData = Theme.of(context);

                      picklists!.remove(picklist);

                      await setPicklists(picklists!);

                      scaffoldMessengerState.showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${picklist.title}"'),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                              label: "Undo",
                              onPressed: () async {
                                try {
                                  picklists!.add(picklist);
                                  await setPicklists(picklists!);
                                  setState(() {});
                                } catch (error) {
                                  scaffoldMessengerState.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error.toString(),
                                        style: TextStyle(
                                            color: themeData
                                                .colorScheme.onErrorContainer),
                                      ),
                                      backgroundColor:
                                          themeData.colorScheme.errorContainer,
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
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    height: 0,
                  ),
                ],
              ))
          .toList(),
    );
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
  List<ConfiguredPicklistMeta>? picklists;
  String? error;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final cached = lovatAPI.getCachedSharedPicklists();
    if (cached != null && picklists == null && error == null) {
      setState(() {
        picklists = cached;
      });
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      final data = await lovatAPI.getSharedPicklists();
      setState(() {
        picklists = data;
        error = null;
      });
    } on LovatAPIException catch (e) {
      if (e.message == "Not on team" && picklists == null) {
        setState(() {
          error = "Not on team";
        });
      } else if (picklists == null) {
        setState(() {
          error = e.toString();
        });
      }
    } catch (e) {
      if (picklists == null) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null && picklists == null) {
      if (error == "Not on team") {
        return const NotOnTeamMessage();
      }
      return FriendlyErrorView(
        errorMessage: error!,
        onRetry: fetchData,
      );
    }

    if (picklists == null) {
      return const Column(children: [LinearProgressIndicator()]);
    }

    return Column(
      children: [
        StaleRefreshIndicator(
          isRefreshing: isRefreshing,
          hasStaleData: picklists != null,
        ),
        Expanded(
          child: ScrollablePageBody(
            padding: EdgeInsets.zero,
            children: picklists!
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
                            final scaffoldMessengerState =
                                ScaffoldMessenger.of(context);
                            final themeData = Theme.of(context);

                            try {
                              scaffoldMessengerState.showSnackBar(
                                const SnackBar(
                                  content: Text("Deleting..."),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              await lovatAPI.deleteSharedPicklist(picklist.id);

                              setState(() {
                                picklists!.removeWhere(
                                    (p) => p.id == picklist.id);
                              });

                              scaffoldMessengerState.hideCurrentSnackBar();

                              scaffoldMessengerState.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Successfully deleted picklist "${picklist.title}"',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (error) {
                              scaffoldMessengerState.hideCurrentSnackBar();

                              scaffoldMessengerState.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error.toString(),
                                    style: TextStyle(
                                        color: themeData
                                            .colorScheme.onErrorContainer),
                                  ),
                                  backgroundColor:
                                      themeData.colorScheme.errorContainer,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          height: 0,
                        ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class NotOnTeamMessage extends StatelessWidget {
  const NotOnTeamMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset("assets/images/welcome-back-dark.png"),
          Text(
            "Strategize with your team",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 7),
          Text(
            "Join a team to collaborate on picklists with your teammates.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class MutablePicklists extends StatefulWidget {
  const MutablePicklists({super.key});

  @override
  State<MutablePicklists> createState() => _MutablePicklistsState();
}

class _MutablePicklistsState extends State<MutablePicklists> {
  List<MutablePicklistMeta>? picklistsMeta;
  String? error;
  bool isRefreshing = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final cached = lovatAPI.getCachedMutablePicklists();
    if (cached != null && picklistsMeta == null && error == null) {
      setState(() {
        picklistsMeta = cached;
      });
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      final data = await lovatAPI.getMutablePicklists();
      setState(() {
        picklistsMeta = data;
        error = null;
      });
    } on LovatAPIException catch (e) {
      if (e.message == "Not on team" && picklistsMeta == null) {
        setState(() {
          error = "Not on team";
        });
      } else if (picklistsMeta == null) {
        setState(() {
          error = e.toString();
        });
      }
    } catch (e) {
      if (picklistsMeta == null) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null && picklistsMeta == null) {
      if (error == "Not on team") {
        return const NotOnTeamMessage();
      }
      return FriendlyErrorView(
        errorMessage: error!,
        onRetry: fetchData,
      );
    }

    if (picklistsMeta == null) {
      return const PageBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            LinearProgressIndicator(),
          ],
        ),
      );
    }

    return Column(
      children: [
        StaleRefreshIndicator(
          isRefreshing: isRefreshing,
          hasStaleData: picklistsMeta != null,
        ),
        Expanded(
          child: ScrollablePageBody(
            padding: EdgeInsets.zero,
            children: picklistsMeta!
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

                              final scaffoldMessengerState =
                                  ScaffoldMessenger.of(context);
                              final themeData = Theme.of(context);

                              try {
                                Navigator.of(context).pushNamed(
                                    '/mutable_picklist',
                                    arguments: <String, dynamic>{
                                      'picklist':
                                          await picklistMeta.getPicklist(),
                                      'callback': () => setState(() {}),
                                    });
                              } catch (error) {
                                scaffoldMessengerState.showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $error",
                                        style: TextStyle(
                                            color: themeData
                                                .colorScheme.onErrorContainer)),
                                    backgroundColor:
                                        themeData.colorScheme.errorContainer,
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
                            final scaffoldMessengerState =
                                ScaffoldMessenger.of(context);
                            final themeData = Theme.of(context);

                            scaffoldMessengerState.showSnackBar(const SnackBar(
                              content: Text("Deleting..."),
                              behavior: SnackBarBehavior.floating,
                            ));

                            try {
                              await picklistMeta.delete();

                              setState(() {
                                picklistsMeta!.removeWhere(
                                    (p) => p.uuid == picklistMeta.uuid);
                              });

                              scaffoldMessengerState.hideCurrentSnackBar();

                              scaffoldMessengerState
                                  .showSnackBar(const SnackBar(
                                content: Text("Successfully deleted"),
                                behavior: SnackBarBehavior.floating,
                              ));
                            } catch (error) {
                              scaffoldMessengerState.hideCurrentSnackBar();

                              scaffoldMessengerState.showSnackBar(SnackBar(
                                content: Text(
                                  "Error deleting: $error",
                                  style: TextStyle(
                                    color:
                                        themeData.colorScheme.onErrorContainer,
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor:
                                    themeData.colorScheme.errorContainer,
                              ));

                              return;
                            }
                          },
                        ),
                        Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          height: 0,
                        ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
