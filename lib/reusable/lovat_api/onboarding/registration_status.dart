import 'dart:convert';

import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension GetRegistrationStatus on LovatAPI {
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

  String? get teamEmail {
    if (status == RegistrationStatus.pendingTeamVerification) {
      return data['teamEmail'];
    }

    if (status == RegistrationStatus.pendingEmailVerification) {
      return data['email'];
    }

    return null;
  }
}
