import 'dart:convert';

import 'package:scouting_dashboard_app/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  ConfiguredPicklist(this.title, this.weights);

  String title;
  List<PicklistWeight> weights;

  String toJSON() => jsonEncode({
        'title': title,
        'weights': weights.map((e) => e.toMap()).toList(),
      });

  factory ConfiguredPicklist.fromJSON(String json) {
    Map<String, dynamic> map = jsonDecode(json);

    return ConfiguredPicklist(
      map['title'],
      (map['weights'] as List<dynamic>)
          .map((e) => PicklistWeight.fromMap(e))
          .toList(),
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

    return ConfiguredPicklist(title, allWeights);
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
