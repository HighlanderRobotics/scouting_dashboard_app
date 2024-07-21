import 'dart:convert';

import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetCSVExport on LovatAPI {
  Future<String> getCSVExport(Tournament tournament, CSVExportMode mode) async {
    final response = await lovatAPI.get(
      '/v1/analysis/${mode.slug}',
      query: {
        'tournamentKey': tournament.key,
      },
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to get CSV export');
      }
    }

    return response!.body;
  }
}

enum CSVExportMode {
  byTeam,
  byScoutReport,
}

extension CSVExportModeExtension on CSVExportMode {
  String get slug {
    switch (this) {
      case CSVExportMode.byTeam:
        return 'csvplain';
      case CSVExportMode.byScoutReport:
        return 'reportcsv';
    }
  }

  String get localizedDescription {
    switch (this) {
      case CSVExportMode.byTeam:
        return 'By team';
      case CSVExportMode.byScoutReport:
        return 'By scout report';
    }
  }

  String get longLocalizedDescription {
    switch (this) {
      case CSVExportMode.byTeam:
        return 'Each row contains a team\'s aggregated statistics throughout the tournament.';
      case CSVExportMode.byScoutReport:
        return 'Each row contains data collected by one scouter about a specific team\'s performance during a match.';
    }
  }
}
