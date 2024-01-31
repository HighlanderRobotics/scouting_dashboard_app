import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/scanner_body.dart';

class ScoutReportScannerPage extends StatefulWidget {
  const ScoutReportScannerPage({super.key});

  @override
  State<ScoutReportScannerPage> createState() => _ScoutReportScannerPageState();
}

class _ScoutReportScannerPageState extends State<ScoutReportScannerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Codes"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      drawer: const GlobalNavigationDrawer(),
      body: ScannerBody(
        onDetect: (p0) => {},
      ),
    );
  }
}
