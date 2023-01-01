import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';

class EditScoutSchedule extends StatefulWidget {
  const EditScoutSchedule({super.key});

  @override
  State<EditScoutSchedule> createState() => _EditScoutScheduleState();
}

class _EditScoutScheduleState extends State<EditScoutSchedule> {
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
            body: const Center(
              child: CircularProgressIndicator(),
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
                              .then((val) {
                            const SnackBar snackBar =
                                SnackBar(content: Text("Saved"));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          });
                          Navigator.pop(context);

                          const SnackBar snackBar =
                              SnackBar(content: Text("Saving..."));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        },
                  icon: const Icon(Icons.check),
                  color: Colors.green,
                )
              ],
            ),
            body: ListView(
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
              child: const Icon(Icons.add),
            ),
          );
  }
}
