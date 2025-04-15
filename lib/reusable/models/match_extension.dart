import 'package:frc_8033_scouting_shared/frc_8033_scouting_shared.dart';

extension GameMatchIdentityExtension on GameMatchIdentity {
  String get shortNameWithTournament =>
      "${getShortLocalizedDescription()} at ${tournamentName ?? tournamentKey}";
}
