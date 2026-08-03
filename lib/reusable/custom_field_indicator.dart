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
          // The container colors in this scheme are identical, so a plain
          // container fill gives no separation on a *Container background. A
          // translucent tint of the text color reads as a soft pill on any
          // background without competing with nearby dividers.
          color: Theme.of(context)
              .colorScheme
              .onSecondaryContainer
              .withValues(alpha: 0.16),
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
