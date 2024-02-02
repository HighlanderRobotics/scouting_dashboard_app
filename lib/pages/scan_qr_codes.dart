import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/navigation_drawer.dart';
import 'package:scouting_dashboard_app/reusable/scanner_body.dart';

class ScoutReportScannerPage extends StatefulWidget {
  const ScoutReportScannerPage({super.key});

  @override
  State<ScoutReportScannerPage> createState() => _ScoutReportScannerPageState();
}

class _ScoutReportScannerPageState extends State<ScoutReportScannerPage> {
  ChunkedScoutReport? report;
  bool uploading = false;
  String? previousCodeValue;

  Future<void> errorHaptics() async {
    await HapticFeedback.heavyImpact();
    await sleep(const Duration(milliseconds: 500));
    await HapticFeedback.lightImpact();
    await sleep(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await sleep(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await sleep(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await sleep(const Duration(milliseconds: 100));
  }

  void showError(BuildContext context, String message) {
    errorHaptics();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void showErrorAcrossAsync(
      ScaffoldMessengerState scaffoldMessenger, String message) {
    errorHaptics();
    scaffoldMessenger.showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget indicator;

    indicator = const Placeholder();

    if (report == null) {
      indicator = Center(
        child: Text(
          "Scan QR codes from Lovat Collection",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    if (report?.isComplete == true) {
      final json = jsonDecode(report!.data) as Map<String, dynamic>;
      final teamNumber = json['teamNumber'] as int;
      final matchType = MatchType.values[json['matchType'] as int];
      final matchNumber = json['matchNumber'] as int;

      final localizedMatch = GameMatchIdentity(matchType, matchNumber, "")
          .getLocalizedDescription(includeTournament: false);

      indicator = Center(
        child: Text(
          "Data on $teamNumber in $localizedMatch",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    if (report?.isComplete == false) {
      indicator = Center(
        child: Text(
          "Scanned ${report!.chunks.length} of ${report!.totalChunks} codes",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Codes"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const GlobalNavigationDrawer(),
      body: ScannerBody(
          onDetect: (data) {
            if (uploading) return;

            final barcode =
                data.barcodes.isNotEmpty ? data.barcodes.first : null;
            if (barcode?.rawValue == null) {
              return;
            }

            if (previousCodeValue == barcode?.rawValue) {
              return;
            }

            previousCodeValue = barcode?.rawValue;

            HapticFeedback.mediumImpact();

            final chunk = ReportChunk(encodedData: barcode!.rawValue!);

            if (report == null) {
              setState(() {
                report = ChunkedScoutReport(chunks: [chunk]);
              });
            } else {
              if (report?.uuid != chunk.uuid) {
                showError(context,
                    "You are scanning a different report. Tap \"Clear\" to start over.");
                return;
              }

              setState(() {
                report!.addChunk(chunk);
              });
            }
          },
          childBelow: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 120, child: indicator),
              FilledButton.tonal(
                onPressed: report == null || uploading
                    ? null
                    : () {
                        setState(() {
                          previousCodeValue = null;
                          report = null;
                        });
                      },
                child: const Text("Clear"),
              ),
              FilledButton(
                onPressed: report?.isComplete == true && !uploading
                    ? () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        try {
                          setState(() {
                            previousCodeValue = null;
                            uploading = true;
                          });

                          await report!.upload();
                          scaffoldMessenger.showSnackBar(const SnackBar(
                            content: Text("Report uploaded"),
                            behavior: SnackBarBehavior.floating,
                          ));

                          setState(() {
                            report = null;
                          });
                        } on LovatAPIException catch (e) {
                          showErrorAcrossAsync(scaffoldMessenger, e.message);
                        } catch (e) {
                          showErrorAcrossAsync(
                              scaffoldMessenger, "An error occurred");
                        } finally {
                          setState(() {
                            uploading = false;
                          });
                        }
                      }
                    : null,
                child: uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      )
                    : const Text("Upload Report"),
              ),
            ],
          )),
      extendBodyBehindAppBar: true,
    );
  }
}

class ChunkedScoutReport {
  const ChunkedScoutReport({
    required this.chunks,
  });

  final List<ReportChunk> chunks;

  int get totalChunks => chunks.first.total;
  bool get isComplete => chunks.length == totalChunks;
  String get uuid => chunks.first.uuid;

  String get data {
    if (!isComplete) {
      throw Exception("Report is not complete");
    }

    return chunks.map((chunk) => chunk.data).join();
  }

  void addChunk(ReportChunk chunk) {
    if (chunks.any((c) => c.index == chunk.index)) {
      throw Exception("Chunk already exists");
    }

    chunks.add(chunk);
  }

  Map<int, ReportChunk?> get chunkMap {
    final map = <int, ReportChunk?>{};

    for (var i = 0; i < totalChunks; i++) {
      map[i] = chunks
          .cast<ReportChunk?>()
          .firstWhere((c) => c?.index == i, orElse: () => null);
    }

    return map;
  }

  Future<void> upload() async {
    if (!isComplete) {
      throw Exception("Report is not complete");
    }

    await lovatAPI.uploadScoutReport(data);
  }
}

class ReportChunk {
  const ReportChunk({
    required this.encodedData,
  });

  final String encodedData;

  int get index => chunkData['index'];
  int get total => chunkData['total'];
  String get uuid => chunkData['uuid'];
  String get data => chunkData['data'];

  Map<String, dynamic> get chunkData {
    final string = Uri.parse(encodedData).queryParameters['d'];

    if (string == null) {
      throw Exception("Invalid QR code");
    }

    return jsonDecode(string) as Map<String, dynamic>;
  }
}

Future<void> sleep(Duration duration) {
  final completer = Completer<void>();
  Timer(duration, completer.complete);
  return completer.future;
}
