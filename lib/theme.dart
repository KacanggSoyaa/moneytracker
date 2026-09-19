import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color seed = Color(0xFF00875A);

  static const Color incomeGreen = Color(0xFF00A86B);
  static const Color expenseRed = Color(0xFFFD3C4A);
  static const Color warningAmber = Color(0xFFFDBC2C);
  static const Color infoBlue = Color(0xFF3B82F6);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final scaffold = isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFECEDEF),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFECEDEF),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}