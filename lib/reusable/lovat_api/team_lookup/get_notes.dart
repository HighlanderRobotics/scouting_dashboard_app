import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/models/match.dart';
import 'package:scouting_dashboard_app/reusable/stale_refresh_builder.dart';

extension NotesQuery on LovatAPI {
  CachedQuery<List<Note>> notesQuery(int teamNumber) {
    final path = '/v1/analysis/notes/team/$teamNumber';
    return CachedQuery(
      queryKey: ['notes', teamNumber],
      label: 'notes',
      queryFn: () async {
        final response = await get(path);

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
      },
      cacheReader: () => getCachedData(
        path,
        parser: (json) {
          final list = json as List<dynamic>;
          final notes = <Note>[];
          for (final map in list) {
            notes.addAll(Note.fromJoinedMap(map as Map<String, dynamic>));
          }
          return notes;
        },
      ),
      cacheTimestampReader: () => getCachedTimestamp(path),
    );
  }
}

enum NoteType { note, breakDescription }

/// A free-form ("Text") custom field answer attached to a scout report, shown
/// below the report's note on the same card.
class CustomTextAnswer {
  const CustomTextAnswer({required this.name, required this.value});

  final String name;
  final String value;

  factory CustomTextAnswer.fromJson(Map<String, dynamic> json) =>
      CustomTextAnswer(
        name: json['name'] as String,
        value: json['value'] as String,
      );
}

class Note {
  const Note({
    required this.body,
    required this.matchIdentity,
    this.author,
    this.uuid,
    this.type = NoteType.note,
    this.customTextAnswers = const [],
  });

  final String body;
  final GameMatchIdentity matchIdentity;
  final String? author;
  final String? uuid;
  final NoteType type;

  /// Text custom field answers from the same report, in field order. Only set
  /// on [NoteType.note] cards.
  final List<CustomTextAnswer> customTextAnswers;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        body: json['notes'],
        matchIdentity: GameMatchIdentity.fromLongKey(json['match'],
            tournamentName: json['tournamentName']),
        author: json['scouterName'],
        uuid: json['uuid'],
      );
  static List<Note> fromJoinedMap(Map<String, dynamic> json) {
    final customTextAnswers = <CustomTextAnswer>[
      if (json['customTextAnswers'] is List)
        ...(json['customTextAnswers'] as List)
            .whereType<Map<String, dynamic>>()
            .map(CustomTextAnswer.fromJson),
    ];

    final hasNote = json["notes"] is String && (json["notes"] as String).isNotEmpty;

    return [
      // One card per report: the written note (if any) together with that
      // report's text custom answers. Emitted when either is present, so a
      // report with only a custom answer still gets a card.
      if (hasNote || customTextAnswers.isNotEmpty)
        Note(
          body: hasNote ? json['notes'] as String : "",
          matchIdentity: GameMatchIdentity.fromLongKey(json['match'],
              tournamentName: json['tournamentName']),
          author: json['scouterName'],
          uuid: json['uuid'],
          customTextAnswers: customTextAnswers,
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
