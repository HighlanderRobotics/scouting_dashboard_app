import 'dart:convert';

import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/reusable/flag_models.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/get_picklist_analysis.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/mutable/create_mutable_picklist.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/mutable/delete_mutable_picklist.dart';
import 'package:scouting_dashboard_app/reusable/lovat_api/picklists/mutable/get_mutable_picklist_by_id.dart';
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
  });

  String path;
  String localizedName;
  double value;

  Map<String, dynamic> toMap() => {
        'path': path,
        'localizedName': localizedName,
        'value': value,
      };

  factory PicklistWeight.fromMap(Map<String, dynamic> map) => PicklistWeight(
        map['path'],
        map['localizedName'],
        value: map['value'],
      );
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
    final analysis = await lovatAPI.getPicklistAnalysis([], weights);

    if (analysis['result'] == null) {
      throw const LovatAPIException("Failed to fetch team rankings.");
    }

    return (analysis['result'] as List<dynamic>)
        .map((e) => e['team'] as int)
        .toList();
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

  factory ConfiguredPicklist.fromServerJSON(String json) {
    Map<String, dynamic> map = jsonDecode(json);

    return ConfiguredPicklist(
      map['name'],
      picklistWeights
          .map((weight) => PicklistWeight(
                weight.path,
                weight.localizedName,
                value: (map[weight.path] ?? 0).toDouble(),
              ))
          .toList(),
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
