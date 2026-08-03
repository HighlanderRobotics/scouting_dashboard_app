import 'dart:convert';

import 'package:scouting_dashboard_app/reusable/lovat_api/lovat_api.dart';

enum CustomFieldType {
  text,
  number,
  singleSelect,
  multiSelect,
}

extension CustomFieldTypeExtension on CustomFieldType {
  String get localizedDescription {
    switch (this) {
      case CustomFieldType.text:
        return "Text";
      case CustomFieldType.number:
        return "Number";
      case CustomFieldType.singleSelect:
        return "Single select";
      case CustomFieldType.multiSelect:
        return "Multi select";
    }
  }

  String get serverValue {
    switch (this) {
      case CustomFieldType.text:
        return "TEXT";
      case CustomFieldType.number:
        return "NUMBER";
      case CustomFieldType.singleSelect:
        return "SINGLE_SELECT";
      case CustomFieldType.multiSelect:
        return "MULTI_SELECT";
    }
  }

  static CustomFieldType fromServerValue(String serverValue) {
    switch (serverValue) {
      case "TEXT":
        return CustomFieldType.text;
      case "NUMBER":
        return CustomFieldType.number;
      case "SINGLE_SELECT":
        return CustomFieldType.singleSelect;
      case "MULTI_SELECT":
        return CustomFieldType.multiSelect;
      default:
        throw ArgumentError.value(
          serverValue,
          'serverValue',
          'Unknown custom field type',
        );
    }
  }
}

class CustomField {
  const CustomField({
    required this.uuid,
    required this.name,
    required this.type,
    this.options = const [],
    this.order = 0,
    this.archived = false,
  });

  final String uuid;
  final String name;
  final CustomFieldType type;
  final List<String> options;
  final int order;
  final bool archived;

  /// The metric path used for this field in analysis surfaces (`cf_<uuid>`).
  String get cfPath => 'cf_$uuid';

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      uuid: json['uuid'],
      name: json['name'],
      type: CustomFieldTypeExtension.fromServerValue(json['type']),
      options: List<String>.from(json['options'] ?? []),
      order: json['order'] ?? 0,
      archived: json['archived'] ?? false,
    );
  }
}

extension CustomFields on LovatAPI {
  /// includeArchived - true: include archived fields, false: active fields only
  Future<List<CustomField>> getCustomFields({
    bool includeArchived = false,
  }) async {
    final response = await get(
      '/v1/manager/customfields',
      query: includeArchived ? null : {'archived': 'false'},
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to get custom fields');
      }
    }

    final json = jsonDecode(response!.body) as List<dynamic>;

    final fields = json
        .map((e) => CustomField.fromJson(e as Map<String, dynamic>))
        .toList();
    fields.sort((a, b) => a.order.compareTo(b.order));
    return fields;
  }

  Future<void> createCustomField({
    required String name,
    required CustomFieldType type,
    List<String> options = const [],
  }) async {
    final response = await post(
      '/v1/manager/customfields',
      body: {
        'name': name,
        'type': type.serverValue,
        if (options.isNotEmpty) 'options': options,
      },
    );

    if (response?.statusCode != 200 && response?.statusCode != 201) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to create custom field');
      }
    }
  }

  Future<void> updateCustomField(
    String uuid, {
    String? name,
    List<String>? options,
  }) async {
    final response = await put(
      '/v1/manager/customfields/$uuid',
      body: {
        if (name != null) 'name': name,
        if (options != null) 'options': options,
      },
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to update custom field');
      }
    }
  }

  /// Edits the text of a single TEXT custom field answer. Only permitted for
  /// scouting leads of the field's team (enforced server-side).
  Future<void> updateCustomFieldAnswer(String answerUuid, String value) async {
    final response = await put(
      '/v1/manager/customfields/answers/$answerUuid',
      body: {'value': value},
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to update custom field answer');
      }
    }
  }

  Future<void> archiveCustomField(String uuid) async {
    final response = await post('/v1/manager/customfields/$uuid/archive');

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to archive custom field');
      }
    }
  }

  Future<void> unarchiveCustomField(String uuid) async {
    final response = await post('/v1/manager/customfields/$uuid/unarchive');

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to unarchive custom field');
      }
    }
  }

  Future<void> reorderCustomFields(List<String> orderedUuids) async {
    final response = await put(
      '/v1/manager/customfields/order',
      body: {
        'fieldUuids': orderedUuids,
      },
    );

    if (response?.statusCode != 200) {
      try {
        throw LovatAPIException(jsonDecode(response!.body)['displayError']);
      } on LovatAPIException {
        rethrow;
      } catch (_) {
        throw Exception('Failed to reorder custom fields');
      }
    }
  }
}

/// Cached custom field definitions (including archived fields), refreshed by
/// [getCustomFieldDefinitions].
List<CustomField>? cachedCustomFields;

/// The team's custom field definitions, including archived fields, fetched
/// from the server the first time (or when [force] is true) and cached in
/// [cachedCustomFields] afterwards.
Future<List<CustomField>> getCustomFieldDefinitions({
  bool force = false,
}) async {
  if (!force && cachedCustomFields != null) {
    return cachedCustomFields!;
  }

  final fields = await lovatAPI.getCustomFields(includeArchived: true);
  cachedCustomFields = fields;
  return fields;
}
