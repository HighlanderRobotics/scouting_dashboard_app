import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/friendly_error_view.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/get_scouts.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/scouter_schedule/create_scout_schedule_shift.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/scouter_schedule/delete_scouter_schedule_shift.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/scouter_schedule/get_scouter_schedule.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/scouter_schedule/update_scouter_schedule_shift.dart';
import 'package:scouting_dashboard_app/reusable/push_widget_extension.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:skeletons/skeletons.dart';

class EditScoutSchedulePage extends StatefulWidget {
  const EditScoutSchedulePage({super.key});

  @override
  State<EditScoutSchedulePage> createState() => _EditScoutSchedulePageState();
}

class _EditScoutSchedulePageState extends State<EditScoutSchedulePage> {
  ServerScoutSchedule? scoutSchedule;
  String? error;

  Future<void> fetchData() async {
    try {
      final scoutSchedule = await lovatAPI.getScouterSchedule();
      debugPrint(scoutSchedule.shifts.toString());
      setState(() {
        this.scoutSchedule = scoutSchedule;
      });
    } catch (e) {
      setState(() {
        error = "Failed to load scout schedule";
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

    if (scoutSchedule != null) {
      body = ListView.builder(
        itemBuilder: (context, index) {
          final shift = scoutSchedule!.shifts[index];
          return Dismissible(
            key: Key(shift.id),
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
            onUpdate: (details) {
              if ((details.reached && !details.previousReached) ||
                  (!details.reached && details.previousReached)) {
                HapticFeedback.lightImpact();
              }
            },
            onDismissed: (direction) async {
              try {
                setState(() {
                  error = null;
                  scoutSchedule = null;
                });

                await lovatAPI.deleteScoutScheduleShift(shift);

                await fetchData();
              } catch (e) {
                setState(() {
                  error = "Failed to delete shift";
                });
              }
            },
            child: ListTile(
              title: Text("${shift.start} to ${shift.end}"),
              subtitle: Text(shift.allScoutsList),
              onTap: () {
                Navigator.of(context).pushWidget(
                  ScoutShiftEditor(
                    initialShift: shift.copy(),
                    onSubmit: (shift) async {
                      if (shift is ServerScoutingShift) {
                        try {
                          setState(() {
                            error = null;
                            scoutSchedule = null;
                          });

                          await lovatAPI.updateScouterScheduleShift(shift);

                          await fetchData();
                        } on LovatAPIException catch (e) {
                          setState(() {
                            error = e.message;
                          });
                        } catch (_) {
                          setState(() {
                            error = "Failed to update shift";
                          });
                        }
                      } else {
                        throw Exception("Invalid shift type");
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
        itemCount: scoutSchedule!.shifts.length,
      );
    }

    if (error != null) {
      body = FriendlyErrorView(
        errorMessage: error!,
        retryLabel: "Reload",
        onRetry: () async {
          setState(() {
            error = null;
            scoutSchedule = null;
          });

          await fetchData();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Scout Schedule"),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushWidget(
            ScoutShiftEditor(
              onSubmit: (shift) async {
                try {
                  setState(() {
                    error = null;
                    scoutSchedule = null;
                  });

                  await lovatAPI.createScoutScheduleShift(shift);

                  await fetchData();
                } on LovatAPIException catch (e) {
                  setState(() {
                    error = e.message;
                  });
                } catch (_) {
                  setState(() {
                    error = "Failed to create shift";
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// This is used for both creating a new shift and editing an existing shift.
class ScoutShiftEditor extends StatefulWidget {
  const ScoutShiftEditor({
    super.key,
    this.initialShift,
    required this.onSubmit,
  });

  final ScoutingShift? initialShift;
  final dynamic Function(ScoutingShift) onSubmit;

  @override
  State<ScoutShiftEditor> createState() => _ScoutShiftEditorState();
}

class _ScoutShiftEditorState extends State<ScoutShiftEditor> {
  ScoutingShift? shift;
  List<Scout>? allScouts;
  String? errorMessage;

  String? startField;
  String? endField;

  bool get startFieldValid => int.tryParse(startField ?? "") != null;
  bool get endFieldValid => int.tryParse(endField ?? "") != null;

  TextEditingController startFieldController = TextEditingController();
  TextEditingController endFieldController = TextEditingController();

  Future<void> fetchData() async {
    debugPrint("Fetching data");
    try {
      setState(() {
        errorMessage = null;
      });
      final allScouts = await lovatAPI.getScouts();
      setState(() {
        this.allScouts = allScouts;
      });
      debugPrint("Done fetching data");
    } catch (e) {
      debugPrint("Failed to fetch data");
      setState(() {
        errorMessage = "Failed to load scouts";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    shift = widget.initialShift ??
        ScoutingShift(
          start: 1,
          end: 1,
          team1: [],
          team2: [],
          team3: [],
          team4: [],
          team5: [],
          team6: [],
        );
    startField = shift!.start.toString();
    endField = shift!.end.toString();
    startFieldController.text = startField!;
    endFieldController.text = endField!;
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return FriendlyErrorView(
        errorMessage: errorMessage!,
        onRetry: () async {
          setState(() {
            errorMessage = null;
            allScouts = null;
          });

          await fetchData();
        },
      );
    }

    if (shift == null || allScouts == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shift"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: shift == null
                ? null
                : () {
                    widget.onSubmit.call(shift!);
                    Navigator.of(context).pop();
                  },
          ),
        ],
      ),
      body: ScrollablePageBody(
        children: [
          TextField(
            decoration: InputDecoration(
              filled: true,
              labelText: "Start match number",
              errorText: startFieldValid ? null : "Invalid",
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                startField = value;
                if (int.tryParse(value) != null) {
                  shift!.start = int.parse(value);
                }
              });
            },
            controller: startFieldController,
          ),
          TextField(
            decoration: InputDecoration(
              filled: true,
              labelText: "End match number",
              errorText: endFieldValid ? null : "Invalid",
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                endField = value;
                if (int.tryParse(value) != null) {
                  shift!.end = int.parse(value);
                }
              });
            },
            controller: endFieldController,
          ),
          ScheduleShiftTeamScouts(
            label: "Red 1",
            scouts: shift!.team1,
            allScouts: allScouts!,
            onChanged: (newValue) {
              setState(() {
                shift!.team1 = newValue;
              });
            },
          ),
          ScheduleShiftTeamScouts(
            label: "Red 2",
            scouts: shift!.team2,
            allScouts: allScouts!,
            onChanged: (newValue) {
              setState(() {
                shift!.team2 = newValue;
              });
            },
          ),
          ScheduleShiftTeamScouts(
            label: "Red 3",
            scouts: shift!.team3,
            allScouts: allScouts!,
            onChanged: (newValue) {
              setState(() {
                shift!.team3 = newValue;
              });
            },
          ),
          ScheduleShiftTeamScouts(
            label: "Blue 1",
            scouts: shift!.team4,
            allScouts: allScouts!,
            onChanged: (newValue) {
              setState(() {
                shift!.team4 = newValue;
              });
            },
          ),
          ScheduleShiftTeamScouts(
            label: "Blue 2",
            scouts: shift!.team5,
            allScouts: allScouts!,
            onChanged: (newValue) {
              setState(() {
                shift!.team5 = newValue;
              });
            },
          ),
          ScheduleShiftTeamScouts(
            label: "Blue 3",
            scouts: shift!.team6,
            allScouts: allScouts!,
            onChanged: (newValue) {
              setState(() {
                shift!.team6 = newValue;
              });
            },
          ),
        ].withSpaceBetween(height: 14),
      ),
    );
  }
}

class ScheduleShiftTeamScouts extends StatelessWidget {
  const ScheduleShiftTeamScouts({
    super.key,
    required this.label,
    required this.scouts,
    required this.allScouts,
    this.onChanged,
  });

  final List<Scout> allScouts;
  final String label;
  final List<Scout> scouts;
  final dynamic Function(List<Scout>)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        ...scouts.map(
          (scout) => ScoutSelector(
            allScouts: allScouts,
            initialScout: scout,
            onChanged: (newScout) {
              final newScouts = scouts.toList();
              if (newScout == null) {
                debugPrint("Removing scout");
                newScouts.remove(scout);
              } else {
                debugPrint("Replacing scout");
                newScouts[scouts.indexOf(scout)] = newScout;
              }
              onChanged?.call(newScouts);
            },
          ),
        ),
        ScoutSelector(
            allScouts: allScouts,
            onChanged: (newScout) {
              final newScouts = scouts.toList();
              newScouts.add(newScout!);
              onChanged?.call(newScouts);
            }),
      ].withSpaceBetween(height: 7),
    );
  }
}

class ScoutSelector extends StatefulWidget {
  const ScoutSelector({
    super.key,
    required this.allScouts,
    this.initialScout,
    this.onChanged,
  });

  final List<Scout> allScouts;
  final Scout? initialScout;
  final dynamic Function(Scout?)? onChanged;

  @override
  State<ScoutSelector> createState() => _ScoutSelectorState();
}

class _ScoutSelectorState extends State<ScoutSelector> {
  Scout? selectedScout;

  @override
  void initState() {
    super.initState();
    selectedScout = widget.initialScout;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch(
      key: Key(selectedScout?.id ?? "null"),
      items: widget.allScouts,
      selectedItem: widget.initialScout,
      onChanged: (scout) {
        setState(() {
          selectedScout = scout;
        });

        widget.onChanged?.call(scout);
      },
      itemAsString: (scout) => scout.name,
      compareFn: (item1, item2) => item1.id == item2.id,
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          filled: true,
          hintText: "Add...",
        ),
      ),
      clearButtonProps: const ClearButtonProps(isVisible: true),
    );
  }
}
