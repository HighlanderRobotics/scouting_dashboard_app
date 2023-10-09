import 'package:custom_qr_generator/custom_qr_generator.dart';
import 'package:flutter/material.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/scrollable_page_body.dart';

class DisplayQRCodesPage extends StatefulWidget {
  const DisplayQRCodesPage({super.key});

  @override
  State<DisplayQRCodesPage> createState() => _DisplayQRCodesPageState();
}

class _DisplayQRCodesPageState extends State<DisplayQRCodesPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("QR Codes"),
          bottom: const TabBar(tabs: [
            Tab(text: "Scouter Schedule"),
            Tab(text: "Server Authority"),
          ]),
        ),
        body: const TabBarView(
          children: [
            ScouterScheduleQRTab(),
            ServerAuthorityQRTab(),
          ],
        ),
      ),
    );
  }
}

class ServerAuthorityQRTab extends StatelessWidget {
  const ServerAuthorityQRTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getServerAuthority(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ScrollablePageBody(
            children: [Center(child: CircularProgressIndicator())],
          );
        }

        final String authority = snapshot.data!;

        return ScrollablePageBody(children: [
          Text(
            "Let other people scan this QR code to set their server authority.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        constraints.maxWidth > 500 ? 500 : constraints.maxWidth,
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
                            data: authority,
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
          RichText(
              text: TextSpan(children: [
            TextSpan(
              text: "Access this code at any time by tapping the ",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const WidgetSpan(
              child: Icon(Icons.qr_code),
              alignment: PlaceholderAlignment.middle,
            ),
            TextSpan(
              text: " at the top right of the match schedule.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ]))
        ]);
      },
    );
  }
}

class ScouterScheduleQRTab extends StatelessWidget {
  const ScouterScheduleQRTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
            "Without an internet connection, scouts should scan this QR code to ensure they have the latest version of the scout schedule, which is version ${schedule.version}.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        constraints.maxWidth > 500 ? 500 : constraints.maxWidth,
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
              color: HSLColor.fromColor(schedule.getVersionColor())
                  .withSaturation(0.5)
                  .withLightness(0.2)
                  .toColor(),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text:
                        "If scouts have the latest version of the schedule, their home page will be this color. If not, they should scan this QR code by tapping the ",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: HSLColor.fromColor(schedule.getVersionColor())
                              .withSaturation(1)
                              .withLightness(0.7)
                              .toColor(),
                        ),
                  ),
                  WidgetSpan(
                    child: Icon(
                      Icons.settings,
                      color: HSLColor.fromColor(schedule.getVersionColor())
                          .withSaturation(1)
                          .withLightness(0.7)
                          .toColor(),
                    ),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  TextSpan(
                    text:
                        " in the top right of their home screen, then tapping the \"Scan Scouter Schedule QR Code\" button.",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: HSLColor.fromColor(schedule.getVersionColor())
                              .withSaturation(1)
                              .withLightness(0.7)
                              .toColor(),
                        ),
                  ),
                ]))),
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
              alignment: PlaceholderAlignment.middle,
            ),
            TextSpan(
              text: " at the top right of the match schedule.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ]))
        ]);
      },
    );
  }
}
