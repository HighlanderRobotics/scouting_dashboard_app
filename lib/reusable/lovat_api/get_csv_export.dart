import 'dart:convert';

import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

extension GetCSVExport on LovatAPI {
  Future<String> getCSVExport(Tournament tournament, CSVExportFormat mode,
      CSVExportFilter filter) async {
    final response = await lovatAPI.get(
      '/v1/analysis/${mode.slug}',
      query: {
        'tournamentKey': tournament.key,
        if (filter != CSVExportFilter.none) filter.slug: ''
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

enum CSVExportFormat {
  byTeam,
  byScoutReport,
}

extension CSVExportFormatExtension on CSVExportFormat {
  String get slug {
    switch (this) {
      case CSVExportFormat.byTeam:
        return 'csvplain';
      case CSVExportFormat.byScoutReport:
        return 'reportcsv';
    }
  }

  String get localizedDescription {
    switch (this) {
      case CSVExportFormat.byTeam:
        return 'By team';
      case CSVExportFormat.byScoutReport:
        return 'By scout report';
    }
  }

  String get longLocalizedDescription {
    switch (this) {
      case CSVExportFormat.byTeam:
        return 'Each row contains a team\'s aggregated statistics throughout the tournament.';
      case CSVExportFormat.byScoutReport:
        return 'Each row contains data collected by one scouter about a specific team\'s performance during a match.';
    }
  }
}

enum CSVExportFilter {
  none,
  auto,
  teleop,
}

extension CSVExportFilterExtension on CSVExportFilter {
  String get slug {
    switch (this) {
      case CSVExportFilter.auto:
        return 'auto';
      case CSVExportFilter.teleop:
        return 'teleop';
      case CSVExportFilter.none:
        return '';
    }
  }

  String get localizedDescription {
    switch (this) {
      case CSVExportFilter.auto:
        return 'Filter to Auto';
      case CSVExportFilter.teleop:
        return 'Filter to Teleop';
      case CSVExportFilter.none:
        return 'Don\'t filter';
    }
  }

  String get longLocalizedDescription {
    switch (this) {
      case CSVExportFilter.auto:
        return 'Calculated only from auto data';
      case CSVExportFilter.teleop:
        return 'Calculated only from teleop data';
      case CSVExportFilter.none:
        return 'Total quantities over entire matches';
    }
  }
}
