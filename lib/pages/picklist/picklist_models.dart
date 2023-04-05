import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:scouting_dashboard_app/analysis_functions/picklist_analysis.dart';
import 'package:scouting_dashboard_app/constants.dart';
import 'package:scouting_dashboard_app/pages/picklist/picklist.dart';
import 'package:scouting_dashboard_app/reusable/page_body.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class PicklistWeight {
  PicklistWeight(
    this.path,
    this.localizedName, {
    this.value = 0.5,
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
  ConfiguredPicklist(this.title, this.weights, this.id);

  factory ConfiguredPicklist.autoUuid(
    String title,
    List<PicklistWeight> weights,
  ) {
    return ConfiguredPicklist(title, weights, (const Uuid()).v4());
  }

  String title;
  List<PicklistWeight> weights;
  String id;

  Future<List<int>> fetchTeamRankings() async {
    Map<String, dynamic> params = weights.asMap().map((key, value) => MapEntry(
          value.path,
          value.value.toString(),
        ));

    params['tournamentKey'] =
        (await SharedPreferences.getInstance()).getString('tournament');

    final response = await http.get(Uri.http(
        (await getServerAuthority())!, "/API/analysis/picklist", params));

    if (response.statusCode != 200) {
      throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
    }

    return (jsonDecode(utf8.decode(response.bodyBytes))[0]['result']
            as List<dynamic>)
        .map((e) => e['team'] as int)
        .toList();
  }

  Future<void> upload() async {
    String authority = (await getServerAuthority())!;

    final response =
        await http.get(Uri.http(authority, '/API/manager/addPicklist', {
      'uuid': id,
      'name': title,
      ...(weights.asMap().map(
            (index, weight) =>
                MapEntry<String, dynamic>(weight.path, weight.value.toString()),
          )),
    }));

    if (response.statusCode != 200) {
      throw "${response.statusCode} ${response.reasonPhrase}: ${response.body}";
    }
  }

  String toJSON() => jsonEncode({
        'title': title,
        'uuid': id,
        'weights': weights.map((e) => e.toMap()).toList(),
      });

  factory ConfiguredPicklist.fromJSON(String json) {
    Map<String, dynamic> map = jsonDecode(json);

    return ConfiguredPicklist(
      map['title'],
      (map['weights'] as List<dynamic>)
          .map((e) => PicklistWeight.fromMap(e))
          .toList(),
      map['uuid'] ?? const Uuid().v4(),
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
    );
  }

  factory ConfiguredPicklist.defaultWeights(
    String title, {
    Map<String, double> weights = const {},
  }) {
    List<PicklistWeight> allWeights = picklistWeights
        .map((e) => weights.containsKey(e.path)
            ? PicklistWeight(e.path, e.localizedName)
            : e)
        .toList();

    return ConfiguredPicklist.autoUuid(title, allWeights);
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
  });

  String uuid;
  String name;
  List<int> teams;

  static Future<MutablePicklist> fromReactivePicklist(
          ConfiguredPicklist reactivePicklist) async =>
      MutablePicklist(
        uuid: reactivePicklist.id,
        name: reactivePicklist.title,
        teams: await reactivePicklist.fetchTeamRankings(),
      );

  factory MutablePicklist.fromJSON(String json) {
    final Map<String, dynamic> decodedJSON = jsonDecode(json);

    return MutablePicklist(
      uuid: decodedJSON['uuid'],
      name: decodedJSON['name'],
      teams: decodedJSON['teams'],
    );
  }

  Future<void> upload() async {
    final authority = (await getServerAuthority())!;

    final response =
        await http.post(Uri.http(authority, '/API/manager/addMutablePicklist'),
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
}
