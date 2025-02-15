import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF350868),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFF3E9FF),
  onPrimaryContainer: Color(0xFF350868),
  secondary: Color(0xFF350868),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFF3E9FF),
  onSecondaryContainer: Color(0xFF350868),
  tertiary: Color(0xFF350868),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFF3E9FF),
  onTertiaryContainer: Color(0xFF350868),
  error: Color(0xFFBA1A1A),
  errorContainer: Color(0xFFFFDAD6),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF410002),
  background: Color(0xFFFFFBFF),
  onBackground: Color(0xFF1D1B1E),
  surface: Color(0xFFFFFBFF),
  onSurface: Color(0xFF1D1B1E),
  surfaceVariant: Color(0xFFDBDBDB),
  onSurfaceVariant: Color(0xFF000000),
  outline: Color(0xFF7D747E),
  onInverseSurface: Color(0xFFF6EFF3),
  inverseSurface: Color(0xFF332F33),
  inversePrimary: Color(0xFFE6B4FF),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF7E469F),
  // outlineVariant: Color(0xFFCEC3CE),
  // scrim: Color(0xFF000000),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFB59AFF),
  onPrimary: Color(0xFF1F1F1F),
  primaryContainer: Color(0xFF282334),
  onPrimaryContainer: Color(0xFFB59AFF),
  secondary: Color(0xFFB59AFF),
  onSecondary: Color(0xFF1F1F1F),
  secondaryContainer: Color(0xFF282334),
  onSecondaryContainer: Color(0xFFB59AFF),
  tertiary: Color(0xFFB59AFF),
  onTertiary: Color(0xFF1F1F1F),
  tertiaryContainer: Color(0xFF282334),
  onTertiaryContainer: Color(0xFFB59AFF),
  error: Color(0xFFFFB4AB),
  errorContainer: Color(0xFF93000A),
  onError: Color(0xFF690005),
  onErrorContainer: Color(0xFFFFDAD6),
  background: Color(0xFF1F1F1F),
  onBackground: Color(0xFFE8E0E5),
  surface: Color(0xFF1F1F1F),
  onSurface: Color(0xFFE8E0E5),
  surfaceVariant: Color(0xFF292929),
  onSurfaceVariant: Color(0xFFCCCCCC),
  outline: Color(0xFF978E98),
  onInverseSurface: Color(0xFF1D1B1E),
  inverseSurface: Color(0xFFE8E0E5),
  inversePrimary: Color(0xFF7E469F),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFE6B4FF),
  outlineVariant: Color(0xFF4B444D),
  // scrim: Color(0xFF000000),
);

extension ColorSchemeExtension on ColorScheme {
  Color get redAlliance => brightness == Brightness.light
      ? const Color.fromARGB(255, 206, 140, 140)
      : const Color(0xFF793F3F);

  Color get blueAlliance => brightness == Brightness.light
      ? const Color.fromARGB(255, 138, 146, 209)
      : const Color(0xFF364077);

  Color get onRedAlliance => brightness == Brightness.light
      ? const Color.fromARGB(255, 107, 50, 50)
      : const Color(0xFFD0A2A2);

  Color get onBlueAlliance => brightness == Brightness.light
      ? const Color.fromARGB(255, 43, 50, 92)
      : const Color(0xFFA2A7D0);

  Color get warningText => brightness == Brightness.light
      ? const Color.fromARGB(255, 223, 235, 97)
      : const Color(0xFFE7EC00);
}
