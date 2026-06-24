import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/get_picklist_analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/shared/get_shared_picklist_by_id.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_indicator.dart';
import 'package:skeletons_forked/skeletons_forked.dart';

class SharedPicklistPage extends StatelessWidget {
  const SharedPicklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    ConfiguredPicklistMeta picklistMeta = (ModalRoute.of(context)!
        .settings
        .arguments as Map<String, dynamic>)['picklist'];

    return Scaffold(
      appBar: AppBar(
        title: Text(picklistMeta.title),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  title: Text("Convert to mutable"),
                  leading: Icon(Icons.swap_vert),
                ),
                onTap: () async {
                  final scaffoldMessengerState = ScaffoldMessenger.of(context);
                  final themeData = Theme.of(context);

                  scaffoldMessengerState.showSnackBar(const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text("Converting to mutable..."),
                  ));

                  try {
                    final picklist = await picklistMeta.getPicklist();
                    final mutablePicklist =
                        await MutablePicklist.fromReactivePicklist(picklist);
                    await mutablePicklist.upload();
                  } catch (error) {
                    scaffoldMessengerState.hideCurrentSnackBar();
                    scaffoldMessengerState.showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          "Error converting to mutable: ${error.toString()}",
                          style: TextStyle(
                              color: themeData.colorScheme.onErrorContainer),
                        ),
                        backgroundColor: themeData.colorScheme.errorContainer,
                      ),
                    );
                    return;
                  }

                  scaffoldMessengerState.hideCurrentSnackBar();
                  scaffoldMessengerState.showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text("Successfully converted to mutable."),
                    ),
                  );
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  title: Text("View weights"),
                  leading: Icon(Icons.balance),
                ),
                onTap: () {
                  Navigator.of(context)
                      .pushNamed('/view_picklist_weights', arguments: {
                    'picklistMeta': picklistMeta,
                  });
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  title: Text("Export CSV"),
                  leading: Icon(Icons.download_outlined),
                ),
                onTap: () async {
                  final picklist = await picklistMeta.getPicklist();
                  if (!context.mounted) return;
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => PicklistExportDrawer(
                      picklistTitle: picklistMeta.title,
                      weights: picklist.weights,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: SharedPicklistView(picklistMeta: picklistMeta),
      ),
    );
  }
}

class SharedPicklistView extends StatefulWidget {
  const SharedPicklistView({super.key, required this.picklistMeta});

  final ConfiguredPicklistMeta picklistMeta;

  @override
  State<SharedPicklistView> createState() => _SharedPicklistViewState();
}

class _SharedPicklistViewState extends State<SharedPicklistView> {
  List<PicklistAnalysisTeam>? data;
  List<FlagConfiguration>? flags;
  String? error;
  bool isRefreshing = false;

  Future<void> fetchData() async {
    final fetchedFlags = await getPicklistFlags();
    final flagPaths = fetchedFlags.map((e) => e.type.path).toList();

    final cachedPicklist =
        lovatAPI.getCachedSharedPicklistById(widget.picklistMeta.id);
    if (cachedPicklist != null && data == null && error == null) {
      final cachedAnalysis =
          lovatAPI.getCachedPicklistAnalysis(flagPaths, cachedPicklist.weights);
      if (cachedAnalysis != null) {
        setState(() {
          flags = fetchedFlags;
          data = cachedAnalysis;
        });
      }
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      final picklist = await widget.picklistMeta.getPicklist();
      final result =
          await lovatAPI.getPicklistAnalysis(flagPaths, picklist.weights);
      setState(() {
        flags = fetchedFlags;
        data = result;
        error = null;
      });
    } on LovatAPIException catch (e) {
      if (data == null) {
        setState(() => error = e.message);
      }
    } catch (_) {
      if (data == null) {
        setState(() => error = "Failed to load picklist");
      }
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null && data == null) {
      return FriendlyErrorView(errorMessage: error, onRetry: fetchData);
    }

    if (data == null || flags == null) {
      return SkeletonListView(
        itemBuilder: (context, index) => SkeletonListTile(),
      );
    }

    final result = data!;

    return Column(
      children: [
        StaleRefreshIndicator(
          isRefreshing: isRefreshing,
          hasStaleData: data != null,
        ),
        Expanded(
          child: ListView(
            children: result
                .map((teamData) => ListTile(
                      title: Text(teamData.teamNumber.toString()),
                      contentPadding: const EdgeInsets.only(left: 16, right: 4),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FlagRow(
                            flags!,
                            Map.fromEntries(
                              teamData.flags
                                  .map((e) => MapEntry(e.type, e.result)),
                            ),
                            teamData.teamNumber,
                            onEdit: fetchData,
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                  "/picklist_team_breakdown",
                                  arguments: {
                                    'team': teamData.teamNumber,
                                    'breakdown': teamData.zScoresWeighted,
                                    'unweighted': teamData.zScoresUnweighted,
                                    'picklistTitle': widget.picklistMeta.title,
                                  });
                            },
                            icon: Icon(
                              Icons.balance,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            tooltip: "View ${teamData.teamNumber}'s z-scores",
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed("/team_lookup", arguments: {
                                'team': teamData.teamNumber,
                              });
                            },
                            icon: Icon(
                              Icons.arrow_right,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            tooltip:
                                "Open team lookup for ${teamData.teamNumber}",
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
