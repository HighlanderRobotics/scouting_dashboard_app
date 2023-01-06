import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants.dart';

class TournamentSelector extends StatefulWidget {
  const TournamentSelector({super.key});

  @override
  State<TournamentSelector> createState() => _TournamentSelectorState();
}

class _TournamentSelectorState extends State<TournamentSelector> {
  Tournament? selectedTournament;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tournament")),
      body: ScrollablePageBody(children: [
        Text(
          "I am at...",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        DropdownSearch(
          popupProps: const PopupProps.menu(
            // showSelectedItems: true,
            fit: FlexFit.loose,
          ),
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
                labelText: "Tournament", border: OutlineInputBorder()),
          ),
          items: tournamentList,
          onChanged: (value) {
            setState(() {
              selectedTournament = value;
            });
          },
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: selectedTournament == null
                  ? null
                  : () async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();

                      await prefs.setString(
                          "tournament", selectedTournament!.key);

                      // ignore: use_build_context_synchronously
                      Navigator.of(context)
                          .pushNamed("/server_authority_setup");
                    },
              child: const Text("Next"),
            ),
          ],
        ),
      ]),
    );
  }
}
