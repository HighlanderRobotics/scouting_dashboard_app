import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class MoreInfoArgs {
  const MoreInfoArgs({
    required this.onContinue,
  });

  final dynamic Function() onContinue;
}

class MoreInfoPage extends StatelessWidget {
  const MoreInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as MoreInfoArgs;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome Back"),
      ),
      body: ScrollablePageBody(children: [
        Image.asset(Theme.of(context).colorScheme.brightness == Brightness.light
            ? 'assets/images/welcome-back-light.png'
            : 'assets/images/welcome-back-dark.png'),
        const Text(
          "We'll need a bit more information before you can get back to strategizing.",
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: args.onContinue,
              child: const Text("Continue"),
            ),
          ],
        ),
      ]),
    );
  }
}
