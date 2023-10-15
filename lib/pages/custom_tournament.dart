import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:http/http.dart' as http;

class CustomTournamentPage extends StatefulWidget {
  const CustomTournamentPage({
    super.key,
    required this.tournaments,
    this.initialName = '',
    this.onCreate,
  });

  final String initialName;
  final List<Tournament> tournaments;
  final dynamic Function(Tournament value)? onCreate;

  @override
  State<CustomTournamentPage> createState() => _CustomTournamentPageState();
}

class _CustomTournamentPageState extends State<CustomTournamentPage> {
  late final TextEditingController nameController;

  late String name;
  String key = '';
  String location = '';
  DateTime? date;

  bool submitAttempted = false;
  bool isCreating = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.initialName);
    name = widget.initialName;
  }

  bool validate() {
    if (RegExp("^\\s*\$").hasMatch(name)) return false;

    if (RegExp("^\\s*\$").hasMatch(key)) return false;
    if (!RegExp("^\\S*\$").hasMatch(key)) return false;

    final conflictingTournaments =
        widget.tournaments.where((t) => t.key == key);
    if (conflictingTournaments.isNotEmpty) return false;

    if (RegExp("^\\s*\$").hasMatch(location)) return false;
    if (date == null) return false;

    return true;
  }

  void displayError(String error) {
    setState(() {
      isCreating = false;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> create() async {
    setState(() {
      isCreating = true;
    });

    try {
      final authority = (await getServerAuthority())!;
      final response =
          await http.post(Uri.http(authority, '/API/manager/addTournament'),
              headers: {
                'content-type': 'application/json',
              },
              body: jsonEncode({
                'key': key,
                'name': name,
                'location': location,
                'date':
                    "${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}",
              }));
      if (response.statusCode != 200) {
        int? errNo;
        try {
          errNo = jsonDecode(response.body)['result']['errno'];
        } catch (e) {
          displayError("Unable to add tournament.");
          return;
        }

        if (jsonDecode(response.body)['result']['errno'] == 19) {
          displayError("Tournament with key $key already exists");
          return;
        } else {
          displayError("Unable to add tournament. Error no. $errNo");
          return;
        }
      }
    } catch (error) {
      displayError(error.toString());
      return;
    }

    setState(() {
      isCreating = false;
    });

    if (widget.onCreate != null) {
      widget.onCreate!(Tournament(key, "${date!.year} $name"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Tournament"),
      ),
      body: ScrollablePageBody(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              filled: true,
              label: const Text("Name"),
              hintText: "Einstein Field",
              errorText: submitAttempted && RegExp("^\\s*\$").hasMatch(name)
                  ? "Name is required"
                  : null,
            ),
            onChanged: (value) => setState(() => name = value),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
                filled: true,
                label: const Text("Key"),
                hintText: "${DateTime.now().year}cmptx",
                errorText: (() {
                  if (!submitAttempted) return null;

                  if (RegExp("^\\s*\$").hasMatch(key)) return "Key is required";
                  if (!RegExp("^\\S*\$").hasMatch(key)) {
                    return "Cannot contain spaces";
                  }

                  final conflictingTournaments =
                      widget.tournaments.where((t) => t.key == key);
                  if (conflictingTournaments.isNotEmpty) {
                    return "Already used for ${conflictingTournaments.first.localized}";
                  }
                })()),
            onChanged: (value) => setState(() => key = value),
            textInputAction: TextInputAction.next,
            autocorrect: false,
          ),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              filled: true,
              label: const Text("Location"),
              hintText: "Houston",
              errorText: submitAttempted && RegExp("^\\s*\$").hasMatch(location)
                  ? "Location is required"
                  : null,
            ),
            onChanged: (value) => setState(() => location = value),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          DateInput(
            onChanged: (value) => setState(() => date = value),
            decoration: InputDecoration(
              filled: true,
              label: const Text("Date"),
              errorText:
                  submitAttempted && date == null ? "Date is required" : null,
            ),
          ),
          const SizedBox(),
          FilledButton(
            onPressed: (submitAttempted && !validate()) || isCreating
                ? null
                : () {
                    FocusScope.of(context).unfocus();

                    setState(() {
                      submitAttempted = true;
                    });

                    if (validate()) create();
                  },
            child: Text(isCreating ? "Creating..." : "Create"),
          ),
        ].withSpaceBetween(height: 20),
      ),
    );
  }
}

class DateInput extends StatefulWidget {
  const DateInput({
    super.key,
    this.onChanged,
    this.decoration = const InputDecoration(),
  });

  final dynamic Function(DateTime value)? onChanged;
  final InputDecoration decoration;

  @override
  State<DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<DateInput> {
  DateTime? date;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    focusNode.addListener(() {
      setState(() {});

      if (focusNode.hasFocus) {
        showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch -
                  const Duration(days: 365).inMilliseconds),
          lastDate: DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch +
                  const Duration(days: 365).inMilliseconds),
        ).then((value) {
          focusNode.nextFocus();
          onChanged(value!);
        });
      }
    });
  }

  void onChanged(DateTime value) {
    setState(() {
      date = value;
    });

    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTap: () {
          focusNode.requestFocus();
        },
        child: InputDecorator(
          decoration: widget.decoration,
          isEmpty: date == null,
          isFocused: focusNode.hasFocus,
          child: Text(
            date == null ? '' : DateFormat.yMMMMd().format(date!),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
