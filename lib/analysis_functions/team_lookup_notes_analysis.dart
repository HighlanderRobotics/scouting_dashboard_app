import 'package:scouting_dashboard_app/analysis_functions/analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/team_lookup/get_notes.dart';

class TeamLookupNotesAnalysis extends AnalysisFunction {
  TeamLookupNotesAnalysis({
    required this.team,
  });

  int team;

  @override
  Future<List<Note>> getOnlineAnalysis() async {
    return await lovatAPI.getNotesByTeamNumber(team);
  }
}
