import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';

import 'package:http/http.dart' as http;
import 'package:skeletons/skeletons.dart';

class TournamentKeyPicker extends StatefulWidget {
  const TournamentKeyPicker({
    super.key,
    this.decoration,
    required this.onChanged,
    this.initialValue,
  });

  final InputDecoration? decoration;
  final dynamic Function(Tournament) onChanged;
  final Tournament? initialValue;

  @override
  State<TournamentKeyPicker> createState() => _TournamentKeyPickerState();
}

class _TournamentKeyPickerState extends State<TournamentKeyPicker> {
  List<Tournament> tournaments = [];
  bool hasError = false;

  bool initialized = false;
  Tournament? selectedItem;

  Future<void> getTournaments() async {
    late final http.Response response;

    try {
      response = await http.get(Uri.http(
          (await getServerAuthority())!, '/API/manager/getTournaments'));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Error getting tournaments: $error",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ));

      setState(() {
        hasError = true;
      });

      return;
    }

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Error getting tournaments: ${response.statusCode} ${response.reasonPhrase} ${response.body}",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ));

      setState(() {
        hasError = true;
      });

      return;
    }

    List<Map<String, dynamic>> responseList =
        jsonDecode(response.body).cast<Map<String, dynamic>>();

    setState(() {
      tournaments = responseList
          .map((e) => Tournament(e['key'],
              "${RegExp("^\\d+").stringMatch(e['key'] as String)!} ${e['name']}"))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty && !hasError) getTournaments();

    if (!initialized) {
      setState(() {
        selectedItem = widget.initialValue;

        initialized = true;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (tournaments.isEmpty && !hasError)
            ? LayoutBuilder(builder: (context, constraints) {
                return SkeletonAvatar(
                  style: SkeletonAvatarStyle(
                      height: 56,
                      width: constraints.maxWidth,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                      )),
                );
              })
            : DropdownSearch<Tournament>(
                onChanged: (value) {
                  setState(() {
                    selectedItem = value;
                  });
                  widget.onChanged(value!);
                },
                itemAsString: (item) => item.localized,
                items: tournaments,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: widget.decoration,
                ),
                selectedItem: selectedItem,
                popupProps: PopupProps.modalBottomSheet(
                  constraints: const BoxConstraints.expand(),
                  modalBottomSheetProps: ModalBottomSheetProps(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  fit: FlexFit.loose,
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text("Search"),
                    ),
                  ),
                  containerBuilder: (context, popupWidget) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Stack(children: [
                        Column(children: [
                          const SizedBox(height: 40),
                          Expanded(child: popupWidget),
                        ]),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.expand_more),
                            visualDensity: VisualDensity.comfortable,
                          ),
                        )
                      ]),
                    ),
                  ),
                  searchDelay: Duration.zero,
                ),
              ),
        if (hasError) ...[
          const SizedBox(height: 10),
          FilledButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => ManualTournamentInputDialog(
                          onSubmit: widget.onChanged,
                        ));
              },
              child: const Text("Enter manually")),
        ],
      ],
    );
  }
}

class ManualTournamentInputDialog extends StatefulWidget {
  ManualTournamentInputDialog({
    super.key,
    required this.onSubmit,
  });

  void Function(Tournament) onSubmit;

  @override
  State<ManualTournamentInputDialog> createState() =>
      _ManualTournamentInputDialogState();
}

class _ManualTournamentInputDialogState
    extends State<ManualTournamentInputDialog> {
  String name = "";
  String key = "";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onChanged: (value) => setState(() {
                name = value;
              }),
              decoration: const InputDecoration(
                filled: true,
                label: Text("Name"),
                helperText: "Only used visually",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => setState(() {
                key = value;
              }),
              decoration: InputDecoration(
                  filled: true,
                  label: const Text("Key"),
                  errorText: RegExp("^\\d+.+\$").hasMatch(key) || key.isEmpty
                      ? null
                      : "Must include the year, i.e. 2023cafr"),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 10),
                FilledButton(
                    onPressed:
                        !RegExp("^\\d+.+\$").hasMatch(key) || name.isEmpty
                            ? null
                            : () {
                                widget.onSubmit(Tournament(key, name));
                                Navigator.of(context).pop();
                              },
                    child: const Text("Save"))
              ],
            )
          ],
        ),
      ),
    );
  }
}
