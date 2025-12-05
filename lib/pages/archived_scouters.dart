import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/scouters.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_scouter_overviews.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:skeletons_forked/skeletons_forked.dart';

class ArchivedScoutersPage extends StatefulWidget {
  const ArchivedScoutersPage({
    super.key,
    this.onChanged,
  });

  final Function()? onChanged;

  @override
  State<ArchivedScoutersPage> createState() => _ArchivedScoutersPageState();
}

class _ArchivedScoutersPageState extends State<ArchivedScoutersPage> {
  List<ScouterOverview>? scouterOverviews;
  String? error;
  Tournament? tournament;

  String filterText = '';
  Future<void> fetchData() async {
    try {
      setState(() {
        scouterOverviews = null;
        error = null;
      });
      final t = await Tournament.getCurrent();
      final data = await lovatAPI.getScouterOverviews(archivedScouters: true);
      setState(() {
        scouterOverviews = data;
        tournament = t;
      });
    } on LovatAPIException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (_) {
      setState(() {
        error = "Failed to load scouters";
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
    if (scouterOverviews == null) {
      fetchData();
    }

    Widget body = SkeletonListView(
      itemBuilder: (context, index) => SkeletonListTile(),
    );
    final List<ScouterOverview>? filteredScouters;
    if (scouterOverviews != null) {
      filteredScouters = scouterOverviews!
          .where((scout) =>
              scout.scout.name.toLowerCase().contains(filterText.toLowerCase()))
          .toList();
    } else {
      filteredScouters = [];
    }

    if (scouterOverviews != null) {
      if (scouterOverviews!.isEmpty) {
        body = PageBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/no_scouters.png", width: 250),
              const SizedBox(height: 8),
              Text(
                "No archived scouters found",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      } else if (filteredScouters.isEmpty) {
        body = PageBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/no_scouters.png", width: 250),
              const SizedBox(height: 8),
              Text(
                "No results found",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
            ],
          ),
        );
      } else {
        body = ScrollablePageBody(
          padding: EdgeInsets.zero,
          children: filteredScouters
              .map(
                (scouterOverview) => ListTile(
                  leading: Monogram(
                    scouterOverview.scout.name.isNotEmpty
                        ? scouterOverview.scout.name
                            .substring(0, 1)
                            .toUpperCase()
                        : "",
                  ),
                  title: Text(scouterOverview.scout.name),
                  subtitle: Text(tournament == null
                      ? "${scouterOverview.totalMatches} match${scouterOverview.totalMatches == 1 ? '' : 'es'} scouted"
                      : "${scouterOverview.totalMatches} match${scouterOverview.totalMatches == 1 ? '' : 'es'} scouted, ${scouterOverview.missedMatches} missed"),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () {
                    Navigator.of(context).pushWidget(
                      ScouterDetailsPage(
                        scouterOverview: scouterOverview,
                        onChanged: () {
                          fetchData();
                          widget.onChanged?.call();
                        },
                      ),
                    );
                  },
                ),
              )
              .toList(),
        );
      }
    }

    if (error != null) {
      body = FriendlyErrorView(errorMessage: error, onRetry: fetchData);
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text("Archived Scouters"),
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (text) {
                    setState(() {
                      filterText = text;
                    });
                  },
                  decoration: const InputDecoration(
                    filled: true,
                    labelText: "Search",
                  ),
                  autofocus: true,
                ),
              ))),
      body: body,
    );
  }
}
