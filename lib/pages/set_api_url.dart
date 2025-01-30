import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetAPIUrlPage extends StatefulWidget {
  const SetAPIUrlPage({super.key, required this.apiBaseUrl});

  final String apiBaseUrl;

  @override
  State<SetAPIUrlPage> createState() => _SetAPIUrlPageState();
}

class _SetAPIUrlPageState extends State<SetAPIUrlPage> {
  bool connected = false;

  Future<void> setAPIUrl() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('api_base_url', widget.apiBaseUrl);

    lovatAPI.baseUrl = widget.apiBaseUrl;

    setState(() {
      connected = true;
    });
  }

  @override
  void initState() {
    super.initState();
    setAPIUrl();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connected
                  ? "Connected to development server"
                  : "Connecting to development server",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              "Lovat Dashboard will send API requests to ${Uri.parse(widget.apiBaseUrl).host}. You can reset it to production in settings.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            FilledButton(
              onPressed: connected
                  ? () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          "/loading", (route) => false);
                    }
                  : null,
              child: const Text("Home"),
            ),
          ].withSpaceBetween(height: 10),
        ),
      ),
    );
    ;
  }
}
