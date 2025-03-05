import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';

class InsetPicker<T> extends StatelessWidget {
  const InsetPicker(
    this.items, {
    super.key,
    required this.titleBuilder,
    this.descriptionBuilder,
    this.onChanged,
    this.selectedItem,
  });

  final List<T> items;
  final String Function(T item) titleBuilder;
  final String? Function(T item)? descriptionBuilder;

  String? getDescription(T item) =>
      descriptionBuilder == null ? null : descriptionBuilder!(item);

  final T? selectedItem;
  final Function(T? value)? onChanged;

  Widget itemSelector(BuildContext context, T item, {bool selected = false}) {
    String? description = getDescription(item);

    return InkWell(
      onTap: () {
        if (onChanged != null) {
          onChanged!(item);
        }
      },
      child: Row(
        crossAxisAlignment: description != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Radio(
            value: item,
            groupValue: selectedItem,
            onChanged: (value) {
              if (onChanged != null) {
                onChanged!(value);
              }
            },
          ),
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10).copyWith(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    titleBuilder(item),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  if (description != null)
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.bodyText),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmphasizedContainer(
      padding: EdgeInsets.zero,
      child: Column(
        children: items
            .map((item) =>
                itemSelector(context, item, selected: item == selectedItem))
            .toList(),
      ),
    );
  }
}
