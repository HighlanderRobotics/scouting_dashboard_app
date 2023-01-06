import 'package:custom_qr_generator/custom_qr_generator.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class ScoutScheduleQR extends StatefulWidget {
  const ScoutScheduleQR({super.key});

  @override
  State<ScoutScheduleQR> createState() => _ScoutScheduleQRState();
}

class _ScoutScheduleQRState extends State<ScoutScheduleQR> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline Schedule Update"),
      ),
      body: FutureBuilder(
        future: getScoutSchedule(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ScrollablePageBody(
              children: [Center(child: CircularProgressIndicator())],
            );
          }

          final ScoutSchedule schedule = snapshot.data!;

          return ScrollablePageBody(children: [
            Text(
              "Without an internet connection, scouts should scan this QR code to ensure they have the latest version of the scout schedule.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 500
                          ? 500
                          : constraints.maxWidth,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1 / 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(11),
                          child: CustomPaint(
                            painter: QrPainter(
                              data: schedule.toCompressedJSON(),
                              options: const QrOptions(padding: 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: schedule.getVersionColor(),
                borderRadius: const BorderRadius.all(Radius.circular(5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  "If scouts have the latest version of the schedule, the background of their home screen should be this color. If not, they should scan this QR code.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 20),
            RichText(
                text: TextSpan(children: [
              TextSpan(
                text: "Access this code at any time by tapping the ",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const WidgetSpan(
                  child: Icon(Icons.qr_code),
                  alignment: PlaceholderAlignment.middle),
              TextSpan(
                text: " at the top right of the match schedule.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ]))
          ]);
        },
      ),
    );
  }
}
