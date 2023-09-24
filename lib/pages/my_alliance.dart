import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class AllianceOpenerPage extends StatefulWidget {
  const AllianceOpenerPage({super.key});

  @override
  State<AllianceOpenerPage> createState() => _AllianceOpenerPageState();
}

class _AllianceOpenerPageState extends State<AllianceOpenerPage> {
  String field1Val = "";
  String field2Val = "";
  String field3Val = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Alliance")),
      body: ScrollablePageBody(children: [
        TextField(
          decoration: const InputDecoration(
            filled: true,
            label: Text("Team 1"),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            setState(() {
              field1Val = value;
            });
          },
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(
            filled: true,
            label: Text("Team 2"),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            setState(() {
              field2Val = value;
            });
          },
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(
            filled: true,
            label: Text("Team 3"),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            setState(() {
              field3Val = value;
            });
          },
        ),
        const SizedBox(height: 40),
        ElevatedButton(
            onPressed: int.tryParse(field1Val) == null ||
                    int.tryParse(field2Val) == null ||
                    int.tryParse(field3Val) == null
                ? null
                : () {
                    FocusScopeNode focusScope = FocusScope.of(context);

                    if (focusScope.hasFocus && !focusScope.hasPrimaryFocus) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    }

                    Navigator.of(context).pushNamed('/alliance', arguments: {
                      'teams': [
                        int.parse(field1Val),
                        int.parse(field2Val),
                        int.parse(field3Val),
                      ]
                    });
                  },
            child: const Text("View"))
      ]),
      drawer: const GlobalNavigationDrawer(),
    );
  }
}
