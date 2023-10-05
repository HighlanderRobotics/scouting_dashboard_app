import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';

class PreviewOverPage extends StatelessWidget {
  const PreviewOverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Preview is over",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              "Thanks for checking out Lovat! The Lovat Dashboard preview for Chezy Champs is now over. Stay tuned for full availability during the 2024 season.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ].withSpaceBetween(height: 10),
        ),
      ),
    );
  }
}
