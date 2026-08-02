import 'package:flutter/material.dart';

/// A small tonal chip marking a value as coming from a team's custom field.
class CustomFieldIndicator extends StatelessWidget {
  const CustomFieldIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Asked by your team",
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "Custom",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
        ),
      ),
    );
  }
}
