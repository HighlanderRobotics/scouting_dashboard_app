import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';
import 'package:http/http.dart' as http;

class PickedTeamsPage extends StatelessWidget {
  const PickedTeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Picked Teams"),
      ),
      drawer: const GlobalNavigationDrawer(),
      body: PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            PickedTeamAdder(),
            PickedTeamsList(),
          ],
        ),
      ),
    );
  }
}

class PickedTeamAdder extends StatefulWidget {
  const PickedTeamAdder({super.key});

  @override
  State<PickedTeamAdder> createState() => _PickedTeamAdderState();
}

class _PickedTeamAdderState extends State<PickedTeamAdder> {
  String inputValue = "";

  Future<void> submit() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Adding team..."),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final authority = (await getServerAuthority())!;

    final response =
        await http.get(Uri.http(authority, '/API/manager/addPickedTeam', {
      'team': inputValue,
    }));

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${response.statusCode} ${response.reasonPhrase}: ${response.body}",
            style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Successfully marked team as picked."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        label: const Text("Team #"),
        suffixIcon: int.tryParse(inputValue) == null
            ? null
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: submit,
              ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      keyboardType: TextInputType.number,
      onChanged: (value) => setState(() {
        inputValue = value;
      }),
      textInputAction: TextInputAction.done,
    );
  }
}

class PickedTeamsList extends StatelessWidget {
  const PickedTeamsList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("<Insert list of picked teams>");
  }
}
