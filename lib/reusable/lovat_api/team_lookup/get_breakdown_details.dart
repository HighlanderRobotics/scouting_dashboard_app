import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/metrics.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/match.dart';

class BreakdownDetailsReport {
  const BreakdownDetailsReport({
    required this.breakdownPath,
    required this.segmentPath,
    required this.match,
    required this.sourceTeam,
    this.scouterName,
  });

  final String breakdownPath;
  final String segmentPath;

  final GameMatchIdentity match;
  final int sourceTeam;
  final String? scouterName;

  String get segmentName {
    try {
      return breakdowns
          .firstWhere((b) => b.path == breakdownPath)
          .segments
          .firstWhere((segment) => segment.path == segmentPath)
          .localizedNameSingular;
    } on StateError {
      return breakdownPath;
    }
  }

  factory BreakdownDetailsReport.fromJson(
    Map<String, dynamic> json, {
    required breakdownPath,
  }) {
    return BreakdownDetailsReport(
      breakdownPath: breakdownPath,
      segmentPath: json['breakdown'],
      match: GameMatchIdentity.fromLongKey(
        json['key'],
        tournamentName: json['tournamentName'],
      ),
      sourceTeam: json['sourceTeam'],
      scouterName: json['scouter'],
    );
  }
}

class AggregatedMatchReports {
  const AggregatedMatchReports({
    required this.breakdownPath,
    required this.segmentPath,
    required this.reports,
    required this.matchIdentity,
  });

  final String breakdownPath;
  final String segmentPath;
  final GameMatchIdentity matchIdentity;

  final List<BreakdownDetailsReport> reports;

  String get sourceDescription {
    if (reports.length > 1 && reports.any((r) => r.scouterName != null)) {
      return "${reports.firstWhere((r) => r.scouterName != null).scouterName} +${reports.length - 1}";
    }
    if (reports.length > 1) return "${reports.length} reports";
    return reports.firstOrNull?.scouterName ??
        reports.firstOrNull?.sourceTeam.toString() ??
        "Unknown";
  }

  List<String> get sources {
    return reports
        .map((report) => report.scouterName ?? report.sourceTeam.toString())
        .toList();
  }
}

class MatchesWithSegment {
  const MatchesWithSegment({
    required this.breakdownPath,
    required this.segmentPath,
    required this.matches,
  });

  final String breakdownPath;
  final String segmentPath;

  final List<AggregatedMatchReports> matches;

  String get segmentName {
    try {
      return breakdowns
          .firstWhere((b) => b.path == breakdownPath)
          .segments
          .firstWhere((segment) => segment.path == segmentPath)
          .localizedNameSingular;
    } on StateError {
      return breakdownPath;
    }
  }
}

class BreakdownDetailsResponse {
  const BreakdownDetailsResponse({
    required this.teamNumber,
    required this.breakdownPath,
    required this.reports,
  });

  final int teamNumber;
  final String breakdownPath;
  final List<BreakdownDetailsReport> reports;

  factory BreakdownDetailsResponse.fromJson(
    List<Map<String, dynamic>> json, {
    required int teamNumber,
    required String breakdownPath,
  }) {
    return BreakdownDetailsResponse(
      teamNumber: teamNumber,
      breakdownPath: breakdownPath,
      reports: json
          .map((report) => BreakdownDetailsReport.fromJson(
                report,
                breakdownPath: breakdownPath,
              ))
          .toList(),
    );
  }

  List<AggregatedMatchReports> get aggregatedMatchReports {
    List<AggregatedMatchReports> matches = [];

    for (var report in reports) {
      try {
        matches
            .firstWhere(
              (segment) =>
                  segment.segmentPath == report.segmentPath &&
                  segment.matchIdentity.toMediumKey() ==
                      report.match.toMediumKey(),
            )
            .reports
            .add(report);
      } on StateError {
        matches.add(AggregatedMatchReports(
          breakdownPath: report.breakdownPath,
          segmentPath: report.segmentPath,
          matchIdentity: report.match,
          reports: [report],
        ));
      }
    }

    return matches;
  }

  List<MatchesWithSegment> get matchesWithSegments {
    List<MatchesWithSegment> segments = [];

    for (var match in aggregatedMatchReports) {
      try {
        segments
            .firstWhere((segment) => segment.segmentPath == match.segmentPath)
            .matches
            .add(match);
      } on StateError {
        segments.add(MatchesWithSegment(
          breakdownPath: match.breakdownPath,
          segmentPath: match.segmentPath,
          matches: [match],
        ));
      }
    }

    return segments;
  }
}

extension GetBreakdownMetrics on LovatAPI {
  Future<BreakdownDetailsResponse> getBreakdownDetails(
    int teamNumber,
    String breakdownPath,
  ) async {
    final response = await get(
      '/v1/analysis/breakdown/team/$teamNumber/$breakdownPath',
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get breakdown details');
    }

    return BreakdownDetailsResponse.fromJson(
      (jsonDecode(response!.body) as List<dynamic>).cast(),
      teamNumber: teamNumber,
      breakdownPath: breakdownPath,
    );
  }
}
