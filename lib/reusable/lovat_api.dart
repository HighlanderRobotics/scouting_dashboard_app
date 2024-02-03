import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/datatypes.dart';
import 'package:scouting_dashboard_app/pages/match_schedule.dart';
import 'package:scouting_dashboard_app/pages/onboarding/onboarding_page.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist_models.dart';
import 'package:scouting_dashboard_app/reusable/models/team.dart';
import 'package:scouting_dashboard_app/reusable/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LovatAPI {
  const LovatAPI(this.baseUrl);

  final String baseUrl;

  Future<Credentials> login() async {
    final newCredentials = await auth0.webAuthentication().login(
          audience: "https://api.lovat.app",
        );

    await auth0.credentialsManager.storeCredentials(newCredentials);

    return newCredentials;
  }

  Future<String?> getAccessToken() async {
    try {
      final credentials = await auth0.credentialsManager.credentials();

      if (credentials.expiresAt.isBefore(DateTime.now())) {
        if (credentials.refreshToken == null) {
          return (await login()).accessToken;
        }

        final newCredentials = await auth0.api
            .renewCredentials(refreshToken: credentials.accessToken);

        await auth0.credentialsManager.storeCredentials(newCredentials);

        return newCredentials.accessToken;
      } else {
        return credentials.accessToken;
      }
    } on CredentialsManagerException {
      return (await login()).accessToken;
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
    final tournament = await Tournament.getCurrent();

    final response = await get(
      '/v1/analysis/picklist',
      query: {
        if (tournament != null) 'tournamentKey': tournament.key,
        'flags': jsonEncode(flags),
        ...Map.fromEntries(
          weights.map((e) => MapEntry(e.path, e.value.toString())).toList(),
        ),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get picklist analysis');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return {
      'result': json['teams'] as List<dynamic>,
      'flags': json['flags'] as List<dynamic>? ?? [],
    };
  }

  Future<void> sharePicklist(
    ConfiguredPicklist picklist,
  ) async {
    // POST /v1/manager/picklists
    final response = await post(
      '/v1/manager/picklists',
      body: {
        'name': picklist.title,
        ...Map.fromEntries(
          picklist.weights.map((e) => MapEntry(e.path, e.value)),
        ),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to share picklist');
    }
  }

  Future<List<ConfiguredPicklistMeta>> getSharedPicklists() async {
    final response = await get('/v1/manager/picklists');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get shared picklists');
    }

    List<dynamic> parsedResponse = jsonDecode(response!.body);

    debugPrint(parsedResponse.toString());

    return parsedResponse
        .map((e) => ConfiguredPicklistMeta.fromJson(e))
        .toList();
  }

  Future<ConfiguredPicklist> getSharedPicklistById(String id) async {
    final response = await get('/v1/manager/picklists/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get shared picklist');
    }

    return ConfiguredPicklist.fromServerJSON(response!.body);
  }

  Future<void> deleteSharedPicklistById(String id) async {
    final response = await delete('/v1/manager/picklists/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to delete shared picklist');
    }
  }

  Future<void> createMutablePicklist(MutablePicklist picklist) async {
    final tournament = await Tournament.getCurrent();

    final response = await post(
      '/v1/manager/mutablepicklists',
      body: {
        'uuid': picklist.uuid,
        'name': picklist.name,
        'teams': picklist.teams,
        'tournamentKey': tournament?.key,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to create mutable picklist');
    }
  }

  Future<List<MutablePicklistMeta>> getMutablePicklists() async {
    final response = await get('/v1/manager/mutablepicklists');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get mutable picklists');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => MutablePicklistMeta.fromJson(e)).toList();
  }

  Future<MutablePicklist> getMutablePicklistById(String id) async {
    final response = await get('/v1/manager/mutablepicklists/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get mutable picklist');
    }

    return MutablePicklist.fromJSON(response!.body);
  }

  Future<void> deleteMutablePicklistById(String id) async {
    final response = await delete('/v1/manager/mutablepicklists/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to delete mutable picklist');
    }
  }

  Future<void> updateMutablePicklist(MutablePicklist picklist) async {
    final response = await put(
      '/v1/manager/mutablepicklists/${picklist.uuid}',
      body: {
        'name': picklist.name,
        'teams': picklist.teams,
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to update mutable picklist');
    }
  }

  Future<Map<String, dynamic>> getCategoryMetricsByTeamNumber(
    int teamNumber,
  ) async {
    final response = await get(
      '/v1/analysis/category/team/$teamNumber',
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get category metrics');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return json;
  }

  Future<Map<String, dynamic>> getBreakdownMetricsByTeamNumber(
    int teamNumber,
  ) async {
    final response = await get(
      '/v1/analysis/breakdown/team/$teamNumber',
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get breakdown metrics');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return json;
  }

  Future<List<Note>> getNotesByTeamNumber(
    int teamNumber,
  ) async {
    final response = await get('/v1/analysis/notes/team/$teamNumber');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get notes');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => Note.fromJson(e)).toList();
  }

  Future<ServerScoutSchedule> getScouterSchedule() async {
    final tournament = await Tournament.getCurrent();

    if (tournament == null) {
      throw Exception('No tournament selected');
    }

    final response =
        await get('/v1/manager/tournament/${tournament.key}/scoutershifts');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get scouter schedule');
    }

    final json = jsonDecode(response!.body) as Map<String, dynamic>;

    return ServerScoutSchedule.fromJson(json);
  }

  Future<void> updateScouterScheduleShift(
    ServerScoutingShift shift,
  ) async {
    debugPrint(shift.team1.toString());

    final response = await post(
      '/v1/manager/scoutershifts/${shift.id}',
      body: {
        'startMatchOrdinalNumber': shift.start,
        'endMatchOrdinalNumber': shift.end,
        'team1': shift.team1.map((e) => e.id).toList(),
        'team2': shift.team2.map((e) => e.id).toList(),
        'team3': shift.team3.map((e) => e.id).toList(),
        'team4': shift.team4.map((e) => e.id).toList(),
        'team5': shift.team5.map((e) => e.id).toList(),
        'team6': shift.team6.map((e) => e.id).toList(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to update scouter schedule shift');
    }
  }

  Future<List<Scout>> getScouts() async {
    final response = await get('/v1/manager/scoutershift/scouters');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get scouts');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => Scout.fromJson(e)).toList();
  }

  Future<void> deleteScoutScheduleShiftById(String id) async {
    final response = await delete('/v1/manager/scoutershifts/$id');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to delete scouter schedule shift');
    }
  }

  Future<void> deleteScoutScheduleShift(ServerScoutingShift shift) async {
    await deleteScoutScheduleShiftById(shift.id);
  }

  Future<void> createScoutScheduleShift(ScoutingShift shift) async {
    final tournament = await Tournament.getCurrent();

    if (tournament == null) {
      throw const LovatAPIException('No tournament selected');
    }

    final response = await post(
      '/v1/manager/tournament/${tournament.key}/scoutershifts',
      body: {
        'startMatchOrdinalNumber': shift.start,
        'endMatchOrdinalNumber': shift.end,
        'team1': shift.team1.map((e) => e.id).toList(),
        'team2': shift.team2.map((e) => e.id).toList(),
        'team3': shift.team3.map((e) => e.id).toList(),
        'team4': shift.team4.map((e) => e.id).toList(),
        'team5': shift.team5.map((e) => e.id).toList(),
        'team6': shift.team6.map((e) => e.id).toList(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to create scouter schedule shift');
    }
  }

  Future<Map<String, dynamic>> getMetricDetails(
      int teamNumber, String metricPath) async {
    final response =
        await get('/v1/analysis/metric/$metricPath/team/$teamNumber');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get metric details');
    }

    return jsonDecode(response!.body);
  }

  Future<void> uploadScoutReport(String data) async {
    final response = await post(
      '/v1/manager/dashboard/scoutreport',
      body: jsonDecode(data),
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');

      late final Exception exception;

      try {
        exception =
            LovatAPIException(jsonDecode(response!.body)['displayError']);
      } catch (_) {
        exception = Exception('Failed to upload scout report');
      }

      throw exception;
    }
  }

  Future<Map<String, dynamic>> getMatchPrediction(
    int red1,
    int red2,
    int red3,
    int blue1,
    int blue2,
    int blue3,
  ) async {
    final response = await get(
      '/v1/analysis/matchprediction',
      query: {
        'red1': red1.toString(),
        'red2': red2.toString(),
        'red3': red3.toString(),
        'blue1': blue1.toString(),
        'blue2': blue2.toString(),
        'blue3': blue3.toString(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get match prediction');
    }

    return jsonDecode(response!.body);
  }

  Future<Map<String, dynamic>> getAllianceAnalysis(List<int> teams) async {
    final response = await get(
      '/v1/analysis/alliance',
      query: {
        'teamOne': teams[0].toString(),
        'teamTwo': teams[1].toString(),
        'teamThree': teams[2].toString(),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get alliance analysis');
    }

    return jsonDecode(response!.body);
  }

  Future<List<MatchScheduleMatch>> getMatches(
    String tournamentKey, {
    bool? isScouted,
    List<int>? teamNumbers,
  }) async {
    final response = await get(
      "/v1/manager/matches/$tournamentKey",
      query: {
        if (isScouted != null) 'isScouted': isScouted.toString(),
        if (teamNumbers != null) 'teams': jsonEncode(teamNumbers),
      },
    );

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get match schedule');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    debugPrint(response.body);

    return json.map((e) => MatchScheduleMatch.fromJson(e)).toList();
  }

  Future<List<Team>> getTeamsAtTournament(String tournamentKey) async {
    final response = await get("/v1/manager/tournament/$tournamentKey/teams");

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get teams at tournament');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    return json.map((e) => Team.fromJson(e)).toList();
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

class Note {
  const Note({
    required this.body,
    required this.matchIdentity,
    this.author,
  });

  final String body;
  final GameMatchIdentity matchIdentity;
  final String? author;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        body: json['notes'],
        matchIdentity: GameMatchIdentity.fromLongKey(json['match']),
        author: json['scouterName'],
      );
}

class MatchScheduleMatch {
  const MatchScheduleMatch({
    required this.identity,
    required this.isScouted,
    required this.red1,
    required this.red2,
    required this.red3,
    required this.blue1,
    required this.blue2,
    required this.blue3,
  });

  final GameMatchIdentity identity;

  final MatchScheduleTeamInfo red1;
  final MatchScheduleTeamInfo red2;
  final MatchScheduleTeamInfo red3;
  final MatchScheduleTeamInfo blue1;
  final MatchScheduleTeamInfo blue2;
  final MatchScheduleTeamInfo blue3;

  final bool isScouted;

  List<MatchScheduleTeamInfo> get allTeamInfo => [
        red1,
        red2,
        red3,
        blue1,
        blue2,
        blue3,
      ];

  factory MatchScheduleMatch.fromJson(Map<String, dynamic> json) {
    return MatchScheduleMatch(
      identity: GameMatchIdentity(MatchType.values[json['matchType']],
          json['matchNumber'], json['tournamentKey']),
      isScouted: json['scouted'],
      red1: MatchScheduleTeamInfo.fromJson(json['team1']),
      red2: MatchScheduleTeamInfo.fromJson(json['team2']),
      red3: MatchScheduleTeamInfo.fromJson(json['team3']),
      blue1: MatchScheduleTeamInfo.fromJson(json['team4']),
      blue2: MatchScheduleTeamInfo.fromJson(json['team5']),
      blue3: MatchScheduleTeamInfo.fromJson(json['team6']),
    );
  }
}

class MatchScheduleTeamInfo {
  const MatchScheduleTeamInfo({
    required this.teamNumber,
    required this.alliance,
    required this.scouters,
  });

  final int teamNumber;
  final Alliance alliance;
  final List<MatchScheduleScouterInfo> scouters;

  factory MatchScheduleTeamInfo.fromJson(Map<String, dynamic> json) {
    return MatchScheduleTeamInfo(
      teamNumber: json['number'],
      alliance: AllianceExtension.fromString(json['alliance']),
      scouters: (json['scouters'] as List<dynamic>)
          .map((e) => MatchScheduleScouterInfo.fromJson(e))
          .toList(),
    );
  }
}

class MatchScheduleScouterInfo {
  const MatchScheduleScouterInfo({
    required this.name,
    required this.isScouted,
  });

  final String name;
  final bool isScouted;

  factory MatchScheduleScouterInfo.fromJson(Map<String, dynamic> json) {
    return MatchScheduleScouterInfo(
      name: json['name'],
      isScouted: json['scouted'],
    );
  }
}

const lovatAPI = LovatAPI("https://lovat-server-staging.up.railway.app");
