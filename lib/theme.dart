import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color seed = Color(0xFF10B981);

  static const Color accentViolet = Color(0xFF7C4DFF);
  static const Color accentIndigo = Color(0xFF3D5AFE);

  static const Color incomeGreen = Color(0xFF10B981);
  static const Color expenseRed = Color(0xFFFD3C4A);
  static const Color warningAmber = Color(0xFFFDBC2C);
  static const Color infoBlue = Color(0xFF3D5AFE);

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
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          shadows: isDark
              ? [
                  const Shadow(
                    color: Color(0x80FFFFFF),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 6 : 0,
        shadowColor: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : scheme.primary.withValues(alpha: 0.16),
        color: isDark ? const Color(0xE61A1F2B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
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