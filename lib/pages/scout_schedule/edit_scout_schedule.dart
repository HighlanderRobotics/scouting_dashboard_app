import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class EditScoutSchedulePage extends StatefulWidget {
  const EditScoutSchedulePage({super.key});

  @override
  State<EditScoutSchedulePage> createState() => _EditScoutSchedulePageState();
}

class _EditScoutSchedulePageState extends State<EditScoutSchedulePage> {
  Future<void> setOldSchedule() async {
    oldSchedule = await getScoutSchedule();

    setState(() {
      newSchedule = oldSchedule!.copy();
    });
  }

  late final ScoutSchedule? oldSchedule;

  @override
  void initState() {
    super.initState();

    setOldSchedule();
  }

  ScoutSchedule? newSchedule;

  @override
  Widget build(BuildContext context) {
    return newSchedule == null
        ? Scaffold(
            appBar: AppBar(title: const Text("Edit Scout Schedule")),
            body: const ScrollablePageBody(
              children: [
                Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text("Edit Scout Schedule"),
              actions: [
                IconButton(
                  onPressed: areSchedulesEqual(oldSchedule!, newSchedule!) ||
                          newSchedule!.validate() != null
                      ? null
                      : () async {
                          newSchedule!
                              .save((await getServerAuthority())!)
                              .then((response) {
                            SnackBar snackBar = SnackBar(
                              content: Text(response.statusCode == 200
                                  ? "Saved"
                                  : "Error saving: ${response.statusCode} ${response.reasonPhrase}"),
                              behavior: SnackBarBehavior.floating,
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          });
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.check),
                  tooltip: "Save changes",
                  color: Colors.green,
                )
              ],
            ),
            body: ScrollablePageBody(
              padding: EdgeInsets.zero,
              children: [
                if (newSchedule!.validate() != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      newSchedule!.validate()!,
                      style: Theme.of(context).textTheme.titleLarge!.merge(
                            TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                    ),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final shift = newSchedule!.shifts[index];

                    return Dismissible(
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
                        title: Text("Matches ${shift.start} to ${shift.end}"),
                        subtitle: Text(shift.scouts.join(", ")),
                        trailing: const Icon(Icons.arrow_right),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            "/edit_scout_shift",
                            arguments: {
                              'shift': shift,
                              'setParentState': setState,
                            },
                          );
                        },
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          newSchedule!.shifts.removeAt(index);
                        });
                      },
                    );
                  },
                  itemCount: newSchedule!.shifts.length,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/new_scout_shift", arguments: {
                  'schedule': newSchedule,
                  'setParentState': setState,
                });
              },
              tooltip: "New shift",
              child: const Icon(Icons.add),
            ),
          );
  }
}
