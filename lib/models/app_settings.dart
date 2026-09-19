import 'package:flutter/material.dart';

class AppSettings {
  static const String currencyKey = 'currency_symbol';
  static const String themeKey = 'theme_mode';

  final String currencySymbol;
  final ThemeMode themeMode;

  const AppSettings({
    this.currencySymbol = r'$',
    this.themeMode = ThemeMode.system,
  });

  factory AppSettings.fromMap(Map<String, Object?> map) => AppSettings(
        currencySymbol: (map[currencyKey] as String?) ?? r'$',
        themeMode: _themeFromString(map[themeKey] as String?),
      );

  static ThemeMode _themeFromString(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String themeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  AppSettings copyWith({String? currencySymbol, ThemeMode? themeMode}) =>
      AppSettings(
        currencySymbol: currencySymbol ?? this.currencySymbol,
        themeMode: themeMode ?? this.themeMode,
      );
}