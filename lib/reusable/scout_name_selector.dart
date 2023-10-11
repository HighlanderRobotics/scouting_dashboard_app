import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:http/http.dart' as http;

class ScoutNameSelector extends StatefulWidget {
  const ScoutNameSelector({
    super.key,
    required this.label,
    this.initialValue,
    this.onChange,
  });

  final String label;
  final String? initialValue;
  final void Function(dynamic)? onChange;

  @override
  State<ScoutNameSelector> createState() => _ScoutNameSelectorState();
}

class _ScoutNameSelectorState extends State<ScoutNameSelector> {
  List<String>? names;
  String? selectedName;

  Future<List<String>> getNames() async {
    final scoutNames = await getScoutNames();

    setState(() {
      names = scoutNames;
    });

    return scoutNames;
  }

  @override
  void initState() {
    super.initState();

    getNames();
  }

  Future<void> addScouter(
    String scouter,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    Navigator.of(context).pop();

    scaffoldMessenger.showSnackBar(const SnackBar(
      content: Text("Adding..."),
      behavior: SnackBarBehavior.floating,
    ));

    final authority = (await getServerAuthority())!;
    final response =
        await http.get(Uri.http(authority, '/API/manager/newScouter', {
      'scouterName': scouter,
    }));

    if (response.statusCode != 200) {
      scaffoldMessenger.clearSnackBars();

      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text("Error: ${response.body}"),
        behavior: SnackBarBehavior.floating,
      ));

      return;
    }

    scaffoldMessenger.clearSnackBars();

    if (widget.onChange != null) {
      setState(() {
        selectedName = scouter;
      });

      widget.onChange!(scouter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch(
      asyncItems: (text) async {
        return names ?? await getNames();
      },
      popupProps: PopupProps.dialog(
        showSearchBox: true,
        containerBuilder: (context, popupWidget) => Dialog(
          insetPadding: const EdgeInsets.all(15),
          child: popupWidget,
        ),
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            label: Text("Search"),
            border: OutlineInputBorder(),
          ),
        ),
        emptyBuilder: (context, searchEntry) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "No scouters found",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (searchEntry.isNotEmpty) ...[
                Text('Does "$searchEntry" need to scout?'),
                FilledButton(
                  onPressed: () {
                    addScouter(searchEntry, ScaffoldMessenger.of(context));
                  },
                  child: const Text('Add them'),
                )
              ]
            ].withSpaceBetween(height: 10),
          ),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          label: Text(widget.label),
          filled: true,
        ),
      ),
      onChanged: widget.onChange,
      selectedItem: selectedName ?? widget.initialValue,
    );
  }
}
