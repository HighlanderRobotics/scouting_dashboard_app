import 'package:scouting_dashboard_app/reusable/lovat_api/custom_fields.dart';

/// A custom field answer as returned in raw scout report responses.
class CustomFieldAnswerDisplay {
  const CustomFieldAnswerDisplay({
    required this.fieldUuid,
    required this.name,
    required this.type,
    this.options = const [],
    this.order = 0,
    this.archived = false,
    this.textValue,
    this.numberValue,
    this.selections = const [],
  });

  final String fieldUuid;
  final String name;
  final CustomFieldType type;
  final List<String> options;
  final int order;
  final bool archived;
  final String? textValue;
  final double? numberValue;
  final List<String> selections;

  /// The value to display for this answer, depending on [type]:
  /// NUMBER -> [numberValue], TEXT -> [textValue], SINGLE_SELECT -> the first
  /// selection (or null), MULTI_SELECT -> [selections].
  dynamic get displayValue {
    switch (type) {
      case CustomFieldType.text:
        return textValue;
      case CustomFieldType.number:
        return numberValue;
      case CustomFieldType.singleSelect:
        return selections.isNotEmpty ? selections.first : null;
      case CustomFieldType.multiSelect:
        return selections;
    }
  }

  bool get hasDisplayableValue {
    switch (type) {
      case CustomFieldType.text:
        return textValue != null && textValue!.trim().isNotEmpty;
      case CustomFieldType.number:
        return numberValue != null;
      case CustomFieldType.singleSelect:
      case CustomFieldType.multiSelect:
        return selections.isNotEmpty;
    }
  }

  /// Parses a single raw-report entry, returning null for entries that are
  /// malformed or have no displayable value.
  static CustomFieldAnswerDisplay? tryFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;

    final fieldUuid = json['fieldUuid'];
    final name = json['name'];
    final serverType = json['type'];

    if (fieldUuid is! String || name is! String || serverType is! String) {
      return null;
    }

    final CustomFieldType type;
    try {
      type = CustomFieldTypeExtension.fromServerValue(serverType);
    } catch (_) {
      return null;
    }

    final options = json['options'];
    final order = json['order'];
    final textValue = json['textValue'];
    final numberValue = json['numberValue'];
    final selections = json['selections'];

    final answer = CustomFieldAnswerDisplay(
      fieldUuid: fieldUuid,
      name: name,
      type: type,
      options:
          options is List ? options.whereType<String>().toList() : const [],
      order: order is num ? order.toInt() : 0,
      archived: json['archived'] == true,
      textValue: textValue is String ? textValue : null,
      numberValue: numberValue is num ? numberValue.toDouble() : null,
      selections: selections is List
          ? selections.whereType<String>().toList()
          : const [],
    );

    if (!answer.hasDisplayableValue) return null;

    return answer;
  }

  /// Parses the `customFieldAnswers` array from a raw-report response,
  /// tolerating a missing or malformed array and skipping entries with no
  /// displayable value. Results are sorted by field order.
  static List<CustomFieldAnswerDisplay> listFromJson(dynamic json) {
    if (json is! List) return [];

    final answers =
        json.map(tryFromJson).whereType<CustomFieldAnswerDisplay>().toList();
    answers.sort((a, b) => a.order.compareTo(b.order));
    return answers;
  }
}
