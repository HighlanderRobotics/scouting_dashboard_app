import 'dart:convert';

import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/custom_fields.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/get_picklist_analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/mutable/create_mutable_picklist.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/mutable/delete_mutable_picklist.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/mutable/get_mutable_picklist_by_id.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/mutable/update_mutable_picklist.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/shared/get_shared_picklist_by_id.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/shared/share_picklist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class PicklistWeight {
  PicklistWeight(
    this.path,
    this.localizedName, {
    this.value = 0,
    this.isCustom = false,
  });

  String path;
  String localizedName;
  double value;
  final bool isCustom;

  Map<String, dynamic> toMap() => {
        'path': path,
        'localizedName': localizedName,
        'value': value,
        'isCustom': isCustom,
      };

  factory PicklistWeight.fromMap(Map<String, dynamic> map) => PicklistWeight(
        map['path'],
        map['localizedName'],
        value: map['value'],
        isCustom: map['isCustom'] ?? false,
      );
}

/// Builds the full list of picklist weights (all at value 0): the built-in
/// [picklistWeights] plus one weight per NUMBER-type custom field in
/// [fields]. Archived fields are labeled "(archived)" and excluded entirely
/// when [includeArchived] is false.
List<PicklistWeight> allPicklistWeightsFromFields(
  List<CustomField> fields, {
  bool includeArchived = true,
}) {
  return [
    ...picklistWeights
        .map((weight) => PicklistWeight(weight.path, weight.localizedName)),
    ...fields
        .where((field) =>
            field.type == CustomFieldType.number &&
            (includeArchived || !field.archived))
        .map((field) => PicklistWeight(
              field.cfPath,
              field.archived ? '${field.name} (archived)' : field.name,
              isCustom: true,
            )),
  ];
}

/// All available picklist weights: the built-in [picklistWeights] plus the
/// team's NUMBER-type custom fields. Falls back to just the built-ins when
/// the custom field definitions can't be fetched.
Future<List<PicklistWeight>> getAllPicklistWeights({
  bool includeArchived = true,
}) async {
  List<CustomField> fields;
  try {
    fields = await getCustomFieldDefinitions();
  } catch (_) {
    fields = [];
  }
  return allPicklistWeightsFromFields(fields, includeArchived: includeArchived);
}

class ConfiguredPicklist {
  ConfiguredPicklist(this.title, this.weights, this.id, {this.author});

  factory ConfiguredPicklist.autoUuid(
      String title, List<PicklistWeight> weights,
      {String? author}) {
    return ConfiguredPicklist(
      title,
      weights,
      (const Uuid()).v4(),
      author: author,
    );
  }

  String title;
  List<PicklistWeight> weights;
  String id;
  String? author;

  Future<List<int>> fetchTeamRankings() async {
    final analysis =
        await lovatAPI.picklistAnalysisQuery([], weights).queryFn();

    if (analysis.isEmpty) {
      throw const LovatAPIException("Failed to fetch team rankings.");
    }

    return analysis.map((e) => e.teamNumber).toList();
  }

  Future<void> upload() async {
    await lovatAPI.sharePicklist(this);
  }

  String toJSON() => jsonEncode({
        'title': title,
        'uuid': id,
        'weights': weights.map((e) => e.toMap()).toList(),
        if (author != null) 'userName': author,
      });

  factory ConfiguredPicklist.fromJSON(String json) {
    Map<String, dynamic> map = jsonDecode(json);

    return ConfiguredPicklist(
      map['title'],
      (map['weights'] as List<dynamic>)
          .map((e) => PicklistWeight.fromMap(e))
          .toList(),
      map['uuid'] ?? const Uuid().v4(),
      author: map.containsKey('userName') ? map['userName'] : null,
    );
  }

  factory ConfiguredPicklist.fromServerJSON(
    String json, {
    List<PicklistWeight>? allWeights,
  }) {
    Map<String, dynamic> map = jsonDecode(json);

    final Map<String, dynamic> customFieldWeights =
        map['customFieldWeights'] is Map
            ? Map<String, dynamic>.from(map['customFieldWeights'])
            : {};

    double valueForPath(String path) {
      final value =
          path.startsWith('cf_') ? customFieldWeights[path] : map[path];
      return (value ?? 0).toDouble();
    }

    final weights = (allWeights ?? picklistWeights)
        .map((weight) => PicklistWeight(
              weight.path,
              weight.localizedName,
              value: valueForPath(weight.path),
              isCustom: weight.isCustom,
            ))
        .toList();

    // Custom field weights stored on the server but not in [allWeights]
    // (e.g. when the definitions fetch failed) still get rows so their
    // values are preserved; the raw path stands in for the name.
    final knownPaths = weights.map((e) => e.path).toSet();
    for (final path in customFieldWeights.keys) {
      if (path.startsWith('cf_') && !knownPaths.contains(path)) {
        weights.add(PicklistWeight(
          path,
          path,
          value: valueForPath(path),
          isCustom: true,
        ));
      }
    }

    return ConfiguredPicklist(
      map['name'],
      weights,
      map['uuid'],
      author: map.containsKey('userName') ? map['userName'] : null,
    );
  }

  factory ConfiguredPicklist.defaultWeights(
    String title, {
    Map<String, double> weights = const {},
    String? author,
  }) {
    List<PicklistWeight> allWeights = picklistWeights
        .map((e) => weights.containsKey(e.path)
            ? PicklistWeight(e.path, e.localizedName)
            : e)
        .toList();

    return ConfiguredPicklist.autoUuid(title, allWeights, author: author);
  }

  ConfiguredPicklistMeta get meta =>
      ConfiguredPicklistMeta(title, id, author: author);
}

class ConfiguredPicklistMeta {
  const ConfiguredPicklistMeta(this.title, this.id, {this.author});

  final String title;
  final String id;
  final String? author;

  factory ConfiguredPicklistMeta.fromJson(Map<String, dynamic> json) {
    return ConfiguredPicklistMeta(
      json['name'],
      json['uuid'],
      author: json['author']['username'],
    );
  }

  Future<ConfiguredPicklist> getPicklist() async {
    return await lovatAPI.getSharedPicklistById(id);
  }
}

Future<List<ConfiguredPicklist>> getPicklists() async {
  List<String> jsonList =
      (await SharedPreferences.getInstance()).getStringList('picklists')!;

  return jsonList.map((e) => ConfiguredPicklist.fromJSON(e)).toList();
}

Future<void> setPicklists(List<ConfiguredPicklist> picklists) async {
  List<String> jsonList = picklists.map((e) => e.toJSON()).toList();

  await (await SharedPreferences.getInstance())
      .setStringList('picklists', jsonList);
}

Future<void> addPicklist(ConfiguredPicklist picklist) async {
  List<ConfiguredPicklist> picklists = await getPicklists();

  picklists.add(picklist);

  setPicklists(picklists);
}

class MutablePicklist {
  MutablePicklist({
    required this.uuid,
    required this.name,
    required this.teams,
    this.author,
  });

  String uuid;
  String name;
  String? author;
  List<int> teams;

  static Future<MutablePicklist> fromReactivePicklist(
          ConfiguredPicklist reactivePicklist) async =>
      MutablePicklist(
        uuid: reactivePicklist.id,
        name: reactivePicklist.title,
        author: reactivePicklist.author,
        teams: await reactivePicklist.fetchTeamRankings(),
      );

  factory MutablePicklist.fromJSON(String json) {
    final Map<String, dynamic> decodedJSON = jsonDecode(json);

    return MutablePicklist(
      uuid: decodedJSON['uuid'],
      name: decodedJSON['name'],
      author:
          decodedJSON.containsKey('userName') ? decodedJSON['userName'] : null,
      teams: decodedJSON['teams'].cast<int>(),
    );
  }

  Future<void> upload() async {
    await lovatAPI.createMutablePicklist(this);
  }

  Future<void> delete() async {
    final authority = (await getServerAuthority())!;

    final response = await http
        .post(Uri.http(authority, '/API/manager/deleteMutablePicklist'),
            body: jsonEncode({
              'uuid': uuid,
              'name': name,
              'teams': teams,
            }),
            headers: {
          'Content-Type': 'application/json',
        });

    if (response.statusCode != 200) {
      throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
    }
  }

  MutablePicklistMeta get meta =>
      MutablePicklistMeta(uuid: uuid, name: name, author: author);

  Future<void> update() async {
    await lovatAPI.updateMutablePicklist(this);
  }
}

class MutablePicklistMeta {
  MutablePicklistMeta({
    required this.uuid,
    required this.name,
    this.author,
    this.tournamentKey,
  });

  String uuid;
  String name;
  String? author;
  String? tournamentKey;

  factory MutablePicklistMeta.fromJson(Map<String, dynamic> json) {
    return MutablePicklistMeta(
      uuid: json['uuid'],
      name: json['name'],
      author: json['author']['username'],
      tournamentKey: json['tournamentKey'],
    );
  }

  Future<MutablePicklist> getPicklist() async {
    return await lovatAPI.getMutablePicklistById(uuid);
  }

  Future<void> delete() async {
    await lovatAPI.deleteMutablePicklist(uuid);
  }
}
