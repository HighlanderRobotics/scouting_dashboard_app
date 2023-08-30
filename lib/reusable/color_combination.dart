import 'package:flutter/material.dart';

enum ColorCombination {
  plain,
  colored,
  emphasis,
}

extension ColorCombinationExtension on ColorCombination {
  Color getBackgroundColor(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    switch (this) {
      case ColorCombination.plain:
        return colorScheme.surfaceVariant;
      case ColorCombination.colored:
        return colorScheme.primaryContainer;
      case ColorCombination.emphasis:
        return colorScheme.primary;
    }
  }

  Color getForegroundColor(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    switch (this) {
      case ColorCombination.plain:
        return colorScheme.onSurfaceVariant;
      case ColorCombination.colored:
        return colorScheme.onPrimaryContainer;
      case ColorCombination.emphasis:
        return colorScheme.onPrimary;
    }
  }
}
