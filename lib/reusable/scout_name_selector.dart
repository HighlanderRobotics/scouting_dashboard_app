import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';

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

  Future<void> setNames() async {
    final scoutNames = await getScoutNames();

    setState(() {
      names = scoutNames;
    });
  }

  @override
  void initState() {
    super.initState();

    setNames();
  }

  @override
  Widget build(BuildContext context) {
    return names == null
        ? const Center(child: CircularProgressIndicator())
        : DropdownSearch(
            items: names!,
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
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                label: Text(widget.label),
                filled: true,
              ),
            ),
            onChanged: widget.onChange,
            selectedItem: widget.initialValue,
          );
  }
}
