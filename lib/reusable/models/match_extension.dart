import 'package:scouting_dashboard_app/reusable/models/match.dart';

extension GameMatchIdentityExtension on GameMatchIdentity {
  String get shortNameWithTournament =>
      "${getShortLocalizedDescription()} at ${tournamentName ?? tournamentKey}";
}
