import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';

class LovatAPI {
  const LovatAPI(this.baseUrl);

  final String baseUrl;

  Future<String?> getAccessToken() async {
    try {
      final credentials = await auth0.credentialsManager.credentials();
      return credentials.accessToken;
    } on CredentialsManagerException {
      return null;
    }
  }

  Future<http.Response?> get(String path, {Map<String, String>? query}) async {
    final token = await getAccessToken();

    final uri = Uri.parse(baseUrl + path).replace(queryParameters: query);

    return await http.get(uri, headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<http.Response?> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final token = await getAccessToken();

    final uri = Uri.parse(baseUrl + path).replace(queryParameters: query);

    return await http
        .post(uri, body: body != null ? jsonEncode(body) : null, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<http.Response?> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final token = await getAccessToken();

    final uri = Uri.parse(baseUrl + path).replace(queryParameters: query);

    return await http
        .put(uri, body: body != null ? jsonEncode(body) : null, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  Future<http.Response?> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final token = await getAccessToken();

    final uri = Uri.parse(baseUrl + path).replace(queryParameters: query);

    return await http
        .delete(uri, body: body != null ? jsonEncode(body) : null, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

  // Specific endpoints
  Future<PartialTeamList> getTeams({
    int take = 10,
    int skip = 0,
    String filter = '',
  }) async {
    final response = await get(
      '/manager/teams',
      query: {
        'take': take.toString(),
        'skip': skip.toString(),
        'filter': filter,
      },
    );

    if (response?.statusCode != 200) {
      throw Exception('Failed to get teams');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;
    final teamJson = json['teams'] as List<dynamic>;

    final teams = teamJson.map((e) => Team.fromJson(e)).toList();

    return PartialTeamList(teams: teams, total: json['count']);
  }

  Future<void> setUsername(String username) async {
    final response = await post(
      '/manager/onboarding/username',
      body: {
        'username': username,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to set username');
    }
  }

  Future<RegistrationStatus> getRegistrationStatus(int teamNumber) async {
    final response = await get(
      '/manager/registeredteams/$teamNumber/registrationstatus',
    );

    if (response?.statusCode != 200) {
      throw Exception('Failed to get registration status');
    }

    return RegistrationStatusExtension.fromString(response!.body);
  }

  Future<void> registerTeam(int teamNumber, String email) async {
    final response = await post(
      '/manager/onboarding/team',
      body: {
        'email': email,
        'number': teamNumber,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to register team');
    }
  }

  Future<bool> joinTeamByCode(int teamNumber, String code) async {
    final response = await post(
      '/manager/onboarding/teamcode',
      query: {
        'code': code,
        'team': teamNumber.toString(),
      },
    );

    if (response?.statusCode == 200) {
      return true;
    } else if (response?.statusCode == 404) {
      return false;
    } else {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to join team');
    }
  }
}

class PartialTeamList {
  const PartialTeamList({
    required this.teams,
    required this.total,
  });

  final List<Team> teams;
  final int total;
}

enum RegistrationStatus {
  /// The team has not started the registration process
  notStarted,

  /// Someone other than this user has started the registration process but
  /// hasn't finished
  pending,

  /// This user has started the registration process and needs to verify their
  /// team's email
  pendingEmailVerification,

  /// This user has started the registration process and needs to set their
  /// team's website
  pendingTeamWebsite,

  /// This user has started the registration process and needs verification from
  /// Lovat that the email belongs to the team
  pendingTeamVerification,

  /// The team has completed the registration process, and the use is not on it
  registeredNotOnTeam,

  /// The team has completed the registration process, and the user is on it
  registeredOnTeam,
}

extension RegistrationStatusExtension on RegistrationStatus {
  static RegistrationStatus fromString(String status) {
    switch (status) {
      case 'NOT_STARTED':
        return RegistrationStatus.notStarted;
      case 'PENDING':
        return RegistrationStatus.pending;
      case 'PENDING_EMAIL_VERIFICATION':
        return RegistrationStatus.pendingEmailVerification;
      case 'PENDING_TEAM_VERIFICATION':
        return RegistrationStatus.pendingTeamVerification;
      case 'REGISTERED_ON_TEAM':
        return RegistrationStatus.registeredOnTeam;
      case 'REGISTERED_OFF_TEAM':
        return RegistrationStatus.registeredNotOnTeam;
      default:
        throw Exception('Invalid registration status: $status');
    }
  }

  bool get isPending => [
        RegistrationStatus.pending,
        RegistrationStatus.pendingEmailVerification,
        RegistrationStatus.pendingTeamVerification,
      ].contains(this);

  bool get isOnTeam => [
        RegistrationStatus.pendingEmailVerification,
        RegistrationStatus.pendingTeamWebsite,
        RegistrationStatus.pendingTeamVerification,
        RegistrationStatus.registeredOnTeam,
      ].contains(this);
}

const lovatAPI = LovatAPI(
  kDebugMode ? "http://macbook-pro.local:3000" : "https://api.lovat.app",
);
