import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/onboarding/onboarding_page.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';
import 'package:scouting_dashboard_app/reusable/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LovatAPI {
  const LovatAPI(this.baseUrl);

  final String baseUrl;

  Future<String?> getAccessToken() async {
    try {
      final credentials = await auth0.credentialsManager.credentials();

      if (credentials.expiresAt.isBefore(DateTime.now())) {
        if (credentials.refreshToken == null) {
          return (await auth0.webAuthentication().login()).accessToken;
        }

        final newCredentials = await auth0.api
            .renewCredentials(refreshToken: credentials.accessToken);

        await auth0.credentialsManager.storeCredentials(newCredentials);

        return newCredentials.accessToken;
      } else {
        return credentials.accessToken;
      }
    } on CredentialsManagerException {
      return (await auth0.webAuthentication().login()).accessToken;
    }
  }

  Future<http.Response?> get(String path, {Map<String, String>? query}) async {
    final token = await getAccessToken();

    debugPrint(token);

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
    int? take,
    int? skip,
    String filter = '',
  }) async {
    final response = await get(
      '/v1/manager/teams',
      query: {
        if (take != null) 'take': take.toString(),
        if (skip != null) 'skip': skip.toString(),
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

  Future<PartialTournamentList> getTournaments({
    int? take,
    int? skip,
    String filter = '',
  }) async {
    final response = await get(
      '/v1/manager/tournaments',
      query: {
        if (take != null) 'take': take.toString(),
        if (skip != null) 'skip': skip.toString(),
        'filter': filter,
      },
    );

    if (response?.statusCode != 200) {
      throw Exception('Failed to get tournaments');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;
    final tournamentJson = json['tournaments'] as List<dynamic>;

    final tournaments =
        tournamentJson.map((e) => Tournament.fromJson(e)).toList();

    return PartialTournamentList(
      tournaments: tournaments,
      total: json['count'],
    );
  }

  Future<void> setUsername(String username) async {
    final response = await post(
      '/v1/manager/onboarding/username',
      body: {
        'username': username,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to set username');
    }
  }

  Future<RegistrationStatusResponse> getRegistrationStatus(
      int teamNumber) async {
    final response = await get(
      '/v1/manager/registeredteams/$teamNumber/registrationstatus',
    );

    if (response?.statusCode != 200) {
      throw Exception('Failed to get registration status');
    }

    final prefs = await SharedPreferences.getInstance();

    final registrationStatusResponse = RegistrationStatusResponse(
      jsonDecode(response!.body) as Map<String, dynamic>,
    );

    prefs.setString('cachedRegistrationStatus',
        registrationStatusResponse.status.toString());

    return registrationStatusResponse;
  }

  Future<RegistrationStatus> getCachedRegistrationStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedRegistrationStatus =
        prefs.getString('cachedRegistrationStatus');

    if (cachedRegistrationStatus == null) {
      return RegistrationStatus.notStarted;
    }

    return RegistrationStatusExtension.fromString(cachedRegistrationStatus);
  }

  Future<void> registerTeam(int teamNumber, String email) async {
    final response = await post(
      '/v1/manager/onboarding/team',
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
      '/v1/manager/onboarding/teamcode',
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

  Future<LovatUserProfile> getUserProfile() async {
    final response = await get('/v1/manager/profile');

    if (response?.statusCode != 200) {
      throw Exception('Failed to get user profile');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return LovatUserProfile.fromJson(json);
  }

  Future<void> setSourceTeams(
    SourceTeamSettingsMode mode, {
    List<int>? teams,
  }) async {
    final response = await post(
      '/v1/manager/settings/teamsource',
      body: {
        'mode': mode.identifier,
        'teams': teams,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to set source teams');
    }
  }

  Future<SourceTeamSettingsResponse> getSourceTeamSettings() async {
    final response = await get('/v1/manager/settings/teamsource');

    if (response?.statusCode != 200) {
      throw Exception('Failed to get source team settings');
    }

    // body can be "THIS_TEAM", "ALL_TEAMS", or "[1, 2, 3]"

    if (response!.body == 'THIS_TEAM') {
      return const SourceTeamSettingsResponse({
        'mode': 'THIS_TEAM',
      });
    } else if (response.body == 'ALL_TEAMS') {
      return const SourceTeamSettingsResponse({
        'mode': 'ALL_TEAMS',
      });
    } else {
      return SourceTeamSettingsResponse({
        'mode': 'SPECIFIC_TEAMS',
        'teams': jsonDecode(response.body) as List<dynamic>,
      });
    }
  }

  Future<void> setSourceTournamentKeys(
    List<String> tournamentKeys,
  ) async {
    final response = await post(
      '/v1/manager/settings/tournamentsource',
      body: {
        'tournaments': tournamentKeys,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to set source tournaments');
    }
  }

  Future<void> setSourceTournaments(
    List<Tournament> tournaments,
  ) async {
    await setSourceTournamentKeys(tournaments.map((e) => e.key).toList());
  }

  Future<List<String>> getSourceTournamentKeys() async {
    final response = await get('/v1/manager/settings/tournamentsource');

    if (response?.statusCode != 200) {
      throw Exception('Failed to get source tournament keys');
    }

    return (jsonDecode(response!.body) as List<dynamic>).cast<String>();
  }

  Future<void> resendVerificationEmail() async {
    final response =
        await post('/v1/manager/onboarding/resendverificationemail');

    if (response?.statusCode == 200) return;

    if (response?.statusCode == 429) {
      throw const LovatAPIException(
          'Too many emails. Please wait a few minutes.');
    }

    debugPrint(response?.body ?? '');
    throw const LovatAPIException('Failed to resend verification email');
  }

  Future<void> setTeamWebsite(String website) async {
    final response = await post(
      '/v1/manager/onboarding/teamwebsite',
      body: {
        'website': website,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to set team website');
    }
  }

  Future<void> deleteAccount() async {
    final response = await delete('/v1/manager/user');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to delete account');
    }
  }

  Future<List<Analyst>?> getAnalysts() async {
    final response = await get('/v1/manager/analysts');

    if ([403, 404].contains(response?.statusCode)) {
      return null;
    }

    if (response?.statusCode != 200) {
      throw Exception('Failed to get analysts');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => Analyst.fromJson(e)).toList();
  }

  Future<void> promoteAnalyst(String id) async {
    final response = await post(
      '/v1/manager/upgradeuser',
      body: {
        'user': id,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to promote analyst');
    }
  }

  Future<String?> getTeamCode() async {
    final response = await get('/v1/manager/code', query: {
      'uuid': const Uuid().v4(),
    });

    if (response?.statusCode == 403) return null;

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get team code');
    }

    return response!.body;
  }

  Future<Map<String, List<dynamic>>> getPicklistAnalysis(
    List<String> flags,
    List<PicklistWeight> weights,
  ) async {
    final response = await post(
      '/v1/analysis/picklist',
      body: {
        'flags': flags,
        'weights': weights.map((e) => e.toMap()).toList(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get picklist analysis');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return {
      'result': json[0]['result'] as List<dynamic>,
      'flags': json[0]['flags'] as List<dynamic>,
    };
  }
}

class LovatAPIException implements Exception {
  const LovatAPIException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PartialTeamList {
  const PartialTeamList({
    required this.teams,
    required this.total,
  });

  final List<Team> teams;
  final int total;
}

class PartialTournamentList {
  const PartialTournamentList({
    required this.tournaments,
    required this.total,
  });

  final List<Tournament> tournaments;
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
      case 'PENDING_WEBSITE':
        return RegistrationStatus.pendingTeamWebsite;
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

class RegistrationStatusResponse {
  const RegistrationStatusResponse(this.data);

  final Map<String, dynamic> data;

  RegistrationStatus get status =>
      RegistrationStatusExtension.fromString(data['status']);

  String? get teamEmail => status == RegistrationStatus.pendingTeamVerification
      ? data['teamEmail']
      : null;
}

class SourceTeamSettingsResponse {
  const SourceTeamSettingsResponse(this.data);

  final Map<String, dynamic> data;

  SourceTeamSettingsMode get mode =>
      SourceTeamSettingsModeExtension.fromIdentifier(data['mode']);

  List<int>? get teams => mode == SourceTeamSettingsMode.specificTeams
      ? (data['teams'] as List<dynamic>).cast<int>()
      : null;
}

class Analyst {
  const Analyst({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory Analyst.fromJson(Map<String, dynamic> json) => Analyst(
        id: json['id'] as String,
        name: json['username'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': name,
        'email': email,
      };

  Future<void> promote() async {
    await lovatAPI.promoteAnalyst(id);
  }
}

const lovatAPI = LovatAPI("https://lovat-server-staging.up.railway.app");
