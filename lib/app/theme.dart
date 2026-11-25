import 'package:flutter/material.dart';

const kUiAccent = Color(0xFF5B3E96);
const kAppBackground = Color(0xFF1A1625);

ThemeData buildAppTheme() {
  const seed = kUiAccent;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: kAppBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
