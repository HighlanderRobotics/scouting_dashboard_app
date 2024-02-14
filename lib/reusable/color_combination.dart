import 'package:flutter/material.dart';
import 'package:scouting_dashboard_app/color_schemes.g.dart';

enum ColorCombination {
  plain,
  colored,
  emphasis,
  red,
  blue,
  redEmphasis,
  blueEmphasis,
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
      case ColorCombination.red:
        return colorScheme.onRedAlliance;
      case ColorCombination.blue:
        return colorScheme.onBlueAlliance;
      case ColorCombination.redEmphasis:
        return colorScheme.redAlliance;
      case ColorCombination.blueEmphasis:
        return colorScheme.blueAlliance;
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
      case ColorCombination.red:
        return colorScheme.redAlliance;
      case ColorCombination.blue:
        return colorScheme.blueAlliance;
      case ColorCombination.redEmphasis:
        return colorScheme.onRedAlliance;
      case ColorCombination.blueEmphasis:
        return colorScheme.onBlueAlliance;
    }
  }
}
