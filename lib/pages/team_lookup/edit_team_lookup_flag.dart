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
      ),
      body: PageBody(
        padding: EdgeInsets.zero,
        bottom: false,
        child: ListView.builder(
          itemBuilder: (context, index) => ListTile(
            leading: NetworkFlag(
              team: args.team,
              flag: FlagConfiguration.start(flags[index]),
            ),
            title: Text(flags[index].readableName),
            subtitle: Text(flags[index].description),
            trailing: selectedFlag?.type.path == flags[index].path
                ? const Icon(Icons.check)
                : null,
            onTap: () async {
              final flag = FlagConfiguration.start(flags[index]);

              await setFlag(flag);
              args.onChange(flag);

              Navigator.of(context).pop();
            },
          ),
          itemCount: flags.length,
        ),
      ),
    );
  }
}
