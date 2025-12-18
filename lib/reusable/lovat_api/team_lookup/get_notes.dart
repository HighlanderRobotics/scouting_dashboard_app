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

    return json.map((e) => Note.fromJson(e)).toList();
  }
}

class Note {
  const Note({
    required this.body,
    required this.matchIdentity,
    this.author,
    this.uuid,
  });

  final String body;
  final GameMatchIdentity matchIdentity;
  final String? author;
  final String? uuid;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        body: json['notes'],
        matchIdentity: GameMatchIdentity.fromLongKey(json['match'],
            tournamentName: json['tounramentName']),
        author: json['scouterName'],
        uuid: json['uuid'],
      );
}
