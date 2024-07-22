import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_scout_reports_by_scouter.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_scouter_overviews.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/scouter.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:skeletons/skeletons.dart';

class ScoutersPage extends StatefulWidget {
  const ScoutersPage({super.key});

  @override
  State<ScoutersPage> createState() => _ScoutersPageState();
}

class _ScoutersPageState extends State<ScoutersPage> {
  List<ScouterOverview>? scouterOverviews;
  String? error;

  Future<void> fetchData() async {
    try {
      setState(() {
        scouterOverviews = null;
        error = null;
      });

      final data = await lovatAPI.getScouterOverviews();

      setState(() {
        scouterOverviews = data;
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
    Widget body = SkeletonListView(
      itemBuilder: (context, index) => SkeletonListTile(),
    );

    if (scouterOverviews != null) {
      body = ScrollablePageBody(
        padding: EdgeInsets.zero,
        children: scouterOverviews!
            .map(
              (scouterOverview) => ListTile(
                leading: Monogram(
                  scouterOverview.scout.name.substring(0, 1).toUpperCase(),
                ),
                title: Text(scouterOverview.scout.name),
                subtitle: Text(
                  "${scouterOverview.totalMatches} match${scouterOverview.totalMatches == 1 ? '' : 'es'} scouted, ${scouterOverview.missedMatches} missed",
                ),
                trailing: const Icon(Icons.arrow_right),
                onTap: () {
                  Navigator.of(context).pushWidget(
                    ScouterDetailsPage(
                        scouterOverview: scouterOverview,
                        onChanged: () => fetchData()),
                  );
                },
              ),
            )
            .toList(),
      );
    }

    if (error != null) {
      body = FriendlyErrorView(errorMessage: error, onRetry: fetchData);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scouters")),
      drawer: const GlobalNavigationDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AddScouterDialog(onAdd: fetchData),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}

class Monogram extends StatelessWidget {
  const Monogram(
    this.text, {
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ));
  }
}

class AddScouterDialog extends StatefulWidget {
  const AddScouterDialog({
    super.key,
    this.onAdd,
  });

  final Function()? onAdd;

  @override
  State<AddScouterDialog> createState() => _AddScouterDialogState();
}

class _AddScouterDialogState extends State<AddScouterDialog> {
  String name = '';
  bool submitting = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Scouter"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: "Name",
              filled: true,
              errorText: error,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              setState(() {
                name = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: submitting
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: submitting
              ? null
              : () async {
                  setState(() {
                    submitting = true;
                    error = null;
                  });

                  final navigatorState = Navigator.of(context);

                  try {
                    await lovatAPI.addScouter(name);
                    widget.onAdd?.call();
                    navigatorState.pop();
                  } on LovatAPIException catch (e) {
                    setState(() {
                      error = e.message;
                      submitting = false;
                    });
                  } catch (_) {
                    setState(() {
                      error = "Failed to add scouter";
                      submitting = false;
                    });
                  }
                },
          child: submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : const Text("Add"),
        ),
      ],
    );
  }
}

class ScouterDetailsPage extends StatefulWidget {
  const ScouterDetailsPage({
    super.key,
    required this.scouterOverview,
    this.onChanged,
  });

  final ScouterOverview scouterOverview;
  final Function()? onChanged;

  @override
  State<ScouterDetailsPage> createState() => _ScouterDetailsPageState();
}

class _ScouterDetailsPageState extends State<ScouterDetailsPage> {
  late String name;

  List<ScouterPageMinimalScoutReportInfo>? reports;
  Tournament? selectedTournament;
  String? error;

  Future<void> fetchData() async {
    try {
      setState(() {
        reports = null;
        error = null;
      });

      final selectedTournament = await Tournament.getCurrent();
      final data = await lovatAPI
          .getScoutReportsByScouter(widget.scouterOverview.scout.id);

      setState(() {
        this.selectedTournament = selectedTournament;
        reports = data;
      });
    } on LovatAPIException catch (e) {
      setState(() {
        error = e.message;
      });
    } catch (_) {
      setState(() {
        error = "Failed to load scout reports";
      });
    }
  }

  @override
  void initState() {
    super.initState();

    name = widget.scouterOverview.scout.name;
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = SkeletonListView(
      itemBuilder: (context, index) => SkeletonListTile(),
    );

    if (reports != null) {
      body = ScrollablePageBody(
        padding: EdgeInsets.zero,
        children: reports!
            .map(
              (report) => ListTile(
                title: Text(
                  "${report.teamNumber} in ${report.matchIdentity.getLocalizedDescription(includeTournament: selectedTournament == null)}",
                ),
                trailing: const Icon(Icons.arrow_right),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/raw_scout_report',
                    arguments: {
                      'uuid': report.reportId,
                      'teamNumber': report.teamNumber,
                      'matchIdentity': report.matchIdentity,
                      'scoutName': name,
                      'onDeleted': () {
                        fetchData();
                      },
                    },
                  );
                },
              ),
            )
            .toList(),
      );

      if (reports!.isEmpty) {
        body = PageBody(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/no-notes-dark.png", width: 250),
              const SizedBox(height: 8),
              Text(
                "No reports found",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                "$name does not have any data recorded${selectedTournament == null ? '' : ' at ${selectedTournament!.localized}'}.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              )
            ],
          ),
        );
      }
    }

    if (error != null) {
      body = FriendlyErrorView(errorMessage: error, onRetry: fetchData);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [menu(context)],
      ),
      body: body,
    );
  }

  MenuAnchor menu(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-80, 0),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          child: const Text("Rename"),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => RenameScouterDialog(
                scouter: widget.scouterOverview.scout,
                onRenamed: (newName) {
                  setState(() {
                    name = newName;
                  });

                  widget.onChanged?.call();
                },
              ),
            );
          },
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outlined),
          child: const Text("Delete"),
          onPressed: () async {
            showDialog(
              context: context,
              builder: (context) => DeleteScouterDialog(
                  scouter: widget.scouterOverview.scout,
                  onDeleted: () => {
                        widget.onChanged?.call(),
                        Navigator.of(context).pop(),
                      }),
            );
          },
        ),
      ],
      builder: (context, controller, child) => IconButton(
        onPressed: () {
          controller.isOpen ? controller.close() : controller.open();
        },
        icon: const Icon(Icons.more_vert),
      ),
    );
  }
}

class RenameScouterDialog extends StatefulWidget {
  const RenameScouterDialog({
    super.key,
    required this.scouter,
    this.onRenamed,
  });

  final Scout scouter;
  final Function(String newName)? onRenamed;

  @override
  State<RenameScouterDialog> createState() => _RenameScouterDialogState();
}

class _RenameScouterDialogState extends State<RenameScouterDialog> {
  String name = '';
  bool submitting = false;
  String? error;

  late TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.scouter.name);
    name = widget.scouter.name;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Rename Scouter"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: "Name",
              filled: true,
              errorText: error,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              setState(() {
                name = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: submitting
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: submitting
              ? null
              : () async {
                  setState(() {
                    submitting = true;
                    error = null;
                  });

                  try {
                    await lovatAPI.renameScouter(widget.scouter.id, name);
                    widget.onRenamed?.call(name);
                    Navigator.of(context).pop();
                  } on LovatAPIException catch (e) {
                    setState(() {
                      error = e.message;
                      submitting = false;
                    });
                  } catch (_) {
                    setState(() {
                      error = "Failed to rename scouter";
                      submitting = false;
                    });
                  }
                },
          child: submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : const Text("Rename"),
        ),
      ],
    );
  }
}

class DeleteScouterDialog extends StatefulWidget {
  const DeleteScouterDialog({
    super.key,
    required this.scouter,
    this.onDeleted,
  });

  final Scout scouter;
  final Function()? onDeleted;

  @override
  State<DeleteScouterDialog> createState() => _DeleteScouterDialogState();
}

class _DeleteScouterDialogState extends State<DeleteScouterDialog> {
  bool submitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Scouter"),
      content: const Text(
          "Are you sure you want to delete this scouter? This will delete all of their reports."),
      actions: [
        TextButton(
          onPressed: submitting
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: submitting
              ? null
              : () async {
                  setState(() {
                    submitting = true;
                  });

                  try {
                    await lovatAPI.deleteScouter(widget.scouter.id);
                    widget.onDeleted?.call();
                    Navigator.of(context).pop();
                  } on LovatAPIException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Failed to delete scouter: ${e.message}"),
                      behavior: SnackBarBehavior.floating,
                    ));
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Failed to delete scouter"),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
          child: submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : const Text("Delete"),
        ),
      ],
    );
  }
}
