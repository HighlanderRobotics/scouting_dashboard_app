import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/flags.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditPicklistFlagsArgs {
  const EditPicklistFlagsArgs({
    required this.initialFlags,
    required this.initialFlagValues,
    required this.team,
    this.onChange,
  });

  final dynamic Function(List<FlagConfiguration> configurations)? onChange;

  final int team;

  final List<FlagConfiguration> initialFlags;
  final Map<String, dynamic> initialFlagValues;
}

class PopupMenuLabel extends PopupMenuEntry<Never> {
  const PopupMenuLabel({
    super.key,
    required this.text,
  });

  @override
  final double height = 50;

  final Widget text;

  @override
  bool represents(void value) => false;

  @override
  State<PopupMenuLabel> createState() => _PopupMenuLabelState();
}

class _PopupMenuLabelState extends State<PopupMenuLabel> {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: widget.text,
        ),
      );
}

class PopupMenuSlider extends PopupMenuEntry<Never> {
  const PopupMenuSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    required this.onChanged,
    this.onChangeEnd,
    this.thumbColor,
  });

  @override
  final double height = 50;

  final double value;
  final double min;
  final double max;
  final dynamic Function(double value) onChanged;
  final void Function(double)? onChangeEnd;
  final Color? thumbColor;

  @override
  bool represents(void value) => false;

  @override
  State<PopupMenuSlider> createState() => _PopupMenuSliderState();
}

class _PopupMenuSliderState extends State<PopupMenuSlider> {
  late double value;
  @override
  void initState() {
    super.initState();
    setState(() {
      value = widget.value;
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: Slider(
          value: value,
          onChanged: (val) {
            widget.onChanged(val);
            setState(() {
              value = val;
            });
          },
          inactiveColor: Theme.of(context).colorScheme.background,
          min: widget.min,
          max: widget.max,
          onChangeEnd: widget.onChangeEnd,
        ),
      );
}

class EditPicklistFlagsPage extends StatefulWidget {
  const EditPicklistFlagsPage({
    super.key,
  });

  @override
  State<EditPicklistFlagsPage> createState() => _EditPicklistFlagsPageState();
}

class _EditPicklistFlagsPageState extends State<EditPicklistFlagsPage> {
  List<FlagConfiguration>? selectedFlags;
  Map<String, dynamic>? flagValues;

  int? willAcceptIndex;

  int? draggingFromIndex;

  bool argsLoaded = false;
  bool isDragging = false;

  String filterText = "";

  Future<void> save(dynamic Function() callback) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'picklist_flags',
      selectedFlags!.map((e) => jsonEncode(e.toJson())).toList(),
    );

    callback();
  }

  Future<void> loadPreviewValues(int team) async {
    final paths = flags
        .map((e) => e.path)
        .where((f) => !flagValues!.containsKey(f))
        .toList();

    final values = await lovatAPI.getFlags(paths, team);

    setState(() {
      flagValues = {
        ...flagValues!,
        ...values.asMap().map(
              (key, value) => MapEntry(paths[key], value),
            ),
      };
    });
  }

  void willAccept(int index) {
    setState(() {
      willAcceptIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as EditPicklistFlagsArgs;

    if (!argsLoaded) {
      setState(() {
        selectedFlags = args.initialFlags
            .map((e) => FlagConfiguration.fromJson(e.toJson()))
            .toList();
        flagValues = jsonDecode(jsonEncode(args.initialFlagValues));
        argsLoaded = true;
      });

      loadPreviewValues(args.team);
    }

    int i = -1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Tags'),
        scrolledUnderElevation: 0,
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 26),
              child: Center(
                child: Container(
                  width: 215,
                  height: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      width: 2,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Stack(
                          children: selectedFlags!.map(
                        (flag) {
                          i += 1;
                          final a = i;
                          int positionalIndex = i;

                          if (draggingFromIndex != null &&
                              draggingFromIndex! <= positionalIndex) {
                            positionalIndex -= 1;
                          }

                          if (willAcceptIndex != null &&
                              willAcceptIndex! <= positionalIndex) {
                            positionalIndex += 1;
                          }

                          return AnimatedPositioned(
                            top: 10,
                            left: (positionalIndex * 50) + 10,
                            duration: isDragging
                                ? const Duration(milliseconds: 150)
                                : Duration.zero,
                            curve: Curves.easeInOut,
                            child: Hero(
                              tag: '${args.team}-${flag.type.path}-$i',
                              child: Draggable<FlagConfiguration>(
                                data: flag,
                                feedback: flag.getWidget(
                                  context,
                                  flagValues![flag.type.path],
                                ),
                                childWhenDragging: Container(),
                                onDragStarted: () {
                                  setState(() {
                                    draggingFromIndex = a;
                                    isDragging = true;
                                  });
                                },
                                onDragEnd: (details) {
                                  setState(() {
                                    draggingFromIndex = null;
                                    isDragging = false;
                                  });
                                },
                                onDraggableCanceled: (velocity, offset) {
                                  setState(() {
                                    selectedFlags!.remove(flag);
                                  });
                                  save(() => {
                                        if (args.onChange != null)
                                          args.onChange!(selectedFlags!)
                                      });
                                },
                                child: Material(
                                  child: PopupMenuButton(
                                    offset: const Offset(0, 45),
                                    itemBuilder: (context) => <PopupMenuEntry>[
                                      PopupMenuLabel(
                                        text: Text(flag.type.readableName),
                                      ),
                                      if (!flag.type.disableHue)
                                        PopupMenuSlider(
                                          value: flag.hue,
                                          onChanged: (value) => setState(() {
                                            flag.hue = value;
                                          }),
                                          min: 0,
                                          max: 359,
                                          thumbColor: HSLColor.fromAHSL(
                                                  1, flag.hue, 0.5, 0.5)
                                              .toColor(),
                                          onChangeEnd: (v) => save(() => {
                                                if (args.onChange != null)
                                                  args.onChange!(selectedFlags!)
                                              }),
                                        ),
                                      PopupMenuItem(
                                        child: const Text("Remove"),
                                        onTap: () {
                                          setState(() {
                                            selectedFlags!.remove(flag);
                                          });
                                          save(() => {
                                                if (args.onChange != null)
                                                  args.onChange!(selectedFlags!)
                                              });
                                        },
                                      ),
                                    ],
                                    child: flag.getWidget(
                                      context,
                                      flagValues![flag.type.path],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ).toList()),
                      if (((selectedFlags?.length ?? 4) < 4) ||
                          draggingFromIndex != null)
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: List.generate(4, (index) => index)
                                .map((e) => flagDropTarget(e, args.onChange))
                                .toList(),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              filterText = value;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            label: Text("Search"),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      Flexible(
                        child: ListView(
                          children: flags
                              .where(
                                (flag) =>
                                    flag.readableName
                                        .toLowerCase()
                                        .contains(filterText.toLowerCase()) ||
                                    flag.description
                                        .toLowerCase()
                                        .contains(filterText.toLowerCase()),
                              )
                              .map((flag) => ListTile(
                                    title: Text(flag.readableName),
                                    subtitle: Text(flag.description),
                                    leading: Draggable<FlagConfiguration>(
                                      data: FlagConfiguration.start(flag),
                                      feedback:
                                          flagValues!.containsKey(flag.path)
                                              ? FlagConfiguration.start(flag)
                                                  .getWidget(context,
                                                      flagValues![flag.path])
                                              : const SkeletonFlag(),
                                      childWhenDragging: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .background,
                                        ),
                                        height: 40,
                                        width: 40,
                                      ),
                                      child: flagValues!.containsKey(flag.path)
                                          ? FlagConfiguration.start(flag)
                                              .getWidget(context,
                                                  flagValues![flag.path])
                                          : const SkeletonFlag(),
                                      onDragStarted: () {
                                        setState(() {
                                          isDragging = true;
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                      onDragEnd: (details) {
                                        setState(() {
                                          isDragging = false;
                                        });
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  )),
            )
          ],
        ),
      ),
    );
  }

  DragTarget<FlagConfiguration> flagDropTarget(
      int index, dynamic Function(List<FlagConfiguration>)? onSave) {
    return DragTarget<FlagConfiguration>(
      builder: (context, candidateData, rejectedData) {
        return const SizedBox(height: 50, width: 50);
      },
      onWillAccept: (d) {
        HapticFeedback.lightImpact();
        willAccept(index);
        return true;
      },
      onLeave: (d) {
        setState(() {
          willAcceptIndex = null;
        });
      },
      onAccept: (flag) {
        setState(() {
          if (draggingFromIndex != null) {
            selectedFlags!.remove(flag);
          }
          selectedFlags!.insert(min(selectedFlags!.length, index), flag);
          willAcceptIndex = null;
        });
        save(() => {if (onSave != null) onSave(selectedFlags!)});
      },
    );
  }
}
