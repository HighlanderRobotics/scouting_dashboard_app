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
        return colorScheme.primary;
      case ColorCombination.emphasis:
        return colorScheme.primaryContainer;
    }
  }

  Color getForegroundColor(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    switch (this) {
      case ColorCombination.plain:
        return colorScheme.onSurfaceVariant;
      case ColorCombination.colored:
        return colorScheme.onPrimary;
      case ColorCombination.emphasis:
        return colorScheme.onPrimaryContainer;
    }
  }
}
