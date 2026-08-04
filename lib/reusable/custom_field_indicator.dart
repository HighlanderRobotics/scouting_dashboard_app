import 'package:flutter/material.dart';

/// A small tonal chip marking a value as coming from a team's custom field.
class CustomFieldIndicator extends StatelessWidget {
  const CustomFieldIndicator({
    Key? key,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  /// Solid fill for the pill. When null, a translucent tint of the default
  /// text color is used, which reads as a soft pill on any background. Pass an
  /// opaque color to make it a filled chip (e.g. [ColorScheme.primary] to match
  /// the "Scouted" flag).
  final Color? backgroundColor;

  /// Text color. Defaults to [ColorScheme.onSecondaryContainer]. Pair with a
  /// solid [backgroundColor] to keep contrast (e.g. [ColorScheme.onPrimary]).
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: "Asked by your team",
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          // The container colors in this scheme are identical, so a plain
          // container fill gives no separation on a *Container background. A
          // translucent tint of the text color reads as a soft pill on any
          // background without competing with nearby dividers.
          color: backgroundColor ??
              scheme.onSecondaryContainer.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "Custom",
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundColor ?? scheme.onSecondaryContainer,
              ),
        ),
      ),
    );
  }
}
