import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/flags.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditTeamLookupFlagArgs {
  EditTeamLookupFlagArgs({required this.team, required this.onChange});

  final dynamic Function(FlagConfiguration newFlag) onChange;
  final int team;
}

class EditTeamLookupFlagPage extends StatefulWidget {
  const EditTeamLookupFlagPage({super.key});

  @override
  State<EditTeamLookupFlagPage> createState() => _EditTeamLookupFlagStatePage();
}

class _EditTeamLookupFlagStatePage extends State<EditTeamLookupFlagPage> {
  FlagConfiguration? selectedFlag;
  String filterText = "";
  List<FlagType> displayedFlags = List.from(flags);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedFlag = FlagConfiguration.fromJson(
        jsonDecode(prefs.getString('team_lookup_flag')!),
      );
    });
  }

  Future<void> setFlag(FlagConfiguration flag) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedFlag = flag;
    });

    await prefs.setString('team_lookup_flag', jsonEncode(flag.toJson()));
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as EditTeamLookupFlagArgs;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Team Tags"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(85),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Search"),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                final newFlags = flags
                    .where((flag) =>
                        flag.readableName.contains(value) ||
                        flag.description.contains(value))
                    .toList();

                setState(() {
                  filterText = value;
                  displayedFlags = newFlags;
                });
              },
            ),
          ),
        ),
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemBuilder: (context, index) => ListTile(
            leading: NetworkFlag(
              key: Key('flagtile-${displayedFlags[index].path}'),
              team: args.team,
              flag: FlagConfiguration.start(displayedFlags[index]),
            ),
            title: Text(displayedFlags[index].readableName),
            subtitle: Text(displayedFlags[index].description),
            trailing: selectedFlag?.type.path == displayedFlags[index].path
                ? const Icon(Icons.check)
                : null,
            onTap: () async {
              final flag = FlagConfiguration.start(displayedFlags[index]);

              await setFlag(flag);
              args.onChange(flag);

              Navigator.of(context).pop();
            },
          ),
          itemCount: displayedFlags.length,
        ),
      ),
    );
  }
}
