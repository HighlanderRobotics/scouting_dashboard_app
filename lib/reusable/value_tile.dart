import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/reusable/color_combination.dart';
import 'package:scouting_dashboard_app/reusable/emphasized_container.dart';

class ValueTile extends StatelessWidget {
  const ValueTile({
    super.key,
    required this.value,
    required this.label,
    this.colorCombination = ColorCombination.plain,
  });

  final Widget value;
  final Widget label;
  final ColorCombination colorCombination;

  @override
  Widget build(BuildContext context) {
    return EmphasizedContainer(
      color: colorCombination.getBackgroundColor(context),
      child: Column(children: [
        DefaultTextStyle(
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(color: colorCombination.getForegroundColor(context)),
          child: value,
        ),
        DefaultTextStyle(
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .labelLarge!
              .copyWith(color: colorCombination.getForegroundColor(context)),
          child: label,
        ),
      ]),
    );
  }
}
