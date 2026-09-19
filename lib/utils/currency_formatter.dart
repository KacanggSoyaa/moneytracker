import 'package:intl/intl.dart';

final NumberFormat _groupFormat = NumberFormat('#,##0', 'en_US');

class CurrencyFormatter {
  static String formatCents(int cents, String symbol) {
    final negative = cents < 0;
    final abs = cents.abs();
    final whole = abs ~/ 100;
    final frac = (abs % 100).toString().padLeft(2, '0');
    final value = '${_groupFormat.format(whole)}.$frac';
    return '${negative ? '-' : ''}$symbol$value';
  }

  static String formatCompactCents(int cents, String symbol) {
    final abs = cents.abs();
    if (abs >= 100000000) {
      return '$symbol${_groupFormat.format(abs ~/ 100000000)}M';
    }
    if (abs >= 1000000) {
      return '$symbol${_groupFormat.format(abs ~/ 100000)}K';
    }
    return formatCents(cents, symbol);
  }

  static int parseCentsFromInput(String raw) {
    if (raw.contains('.')) {
      final parts = raw.split('.');
      final whole = int.tryParse(parts[0].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      final fracStr = parts.length > 1
          ? '${parts[1].replaceAll(RegExp(r'[^\d]'), '')}00'.substring(0, 2)
          : '00';
      final frac = int.tryParse(fracStr) ?? 0;
      return whole * 100 + frac;
    }
    final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return 0;
    return (int.parse(cleaned)) * 100;
  }
}