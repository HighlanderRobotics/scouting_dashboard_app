import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/match.dart';

extension GetNotes on LovatAPI {
  Future<List<Note>> getNotesByTeamNumber(
    int teamNumber,
  ) async {
    final response = await get('/v1/analysis/notes/team/$teamNumber');

    if (response?.statusCode != 200) {
      debugPrint(response?.body ?? '');
      throw Exception('Failed to get notes');
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    List<Note> notes = [];

    for (final map in json) {
      notes.addAll(Note.fromJoinedMap(map));
    }

    return notes;
  }
}

enum NoteType { note, breakDescription }

class Note {
  const Note({
    required this.body,
    required this.matchIdentity,
    this.author,
    this.uuid,
    this.type = NoteType.note,
  });

  final String body;
  final GameMatchIdentity matchIdentity;
  final String? author;
  final String? uuid;
  final NoteType type;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        body: json['notes'],
        matchIdentity: GameMatchIdentity.fromLongKey(json['match'],
            tournamentName: json['tournamentName']),
        author: json['scouterName'],
        uuid: json['uuid'],
      );
  static List<Note> fromJoinedMap(Map<String, dynamic> json) {
    return [
      if (json.containsKey("notes") &&
          json["notes"].runtimeType == String &&
          (json["notes"] as String).isNotEmpty)
        Note(
          body: json['notes'],
          matchIdentity: GameMatchIdentity.fromLongKey(json['match'],
              tournamentName: json['tournamentName']),
          author: json['scouterName'],
          uuid: json['uuid'],
        ),
      if (json.containsKey("robotBrokeDescription") &&
          json["robotBrokeDescription"].runtimeType == String &&
          (json["robotBrokeDescription"] as String).isNotEmpty)
        Note(
            body: json['robotBrokeDescription'],
            matchIdentity: GameMatchIdentity.fromLongKey(json['match'],
                tournamentName: json['tournamentName']),
            author: json['scouterName'],
            uuid: json['uuid'],
            type: NoteType.breakDescription),
    ];
  }
}
