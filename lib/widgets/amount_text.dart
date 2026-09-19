import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/currency_formatter.dart';

class AmountText extends StatelessWidget {
  final int cents;
  final String symbol;
  final TransactionColor color;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showSign;

  const AmountText({
    super.key,
    required this.cents,
    required this.symbol,
    this.color = TransactionColor.neutral,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = switch (color) {
      TransactionColor.income => AppTheme.incomeGreen,
      TransactionColor.expense => AppTheme.expenseRed,
      TransactionColor.warning => AppTheme.warningAmber,
      TransactionColor.neutral => Theme.of(context).colorScheme.onSurface,
      TransactionColor.inherit => null,
    };
    final prefix = showSign
        ? (cents < 0
            ? '-'
            : color == TransactionColor.income
                ? '+'
                : '')
        : '';
    return Text(
      '$prefix${CurrencyFormatter.formatCents(cents, symbol)}',
      style: TextStyle(
        color: resolved ?? DefaultTextStyle.of(context).style.color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}

enum TransactionColor { income, expense, warning, neutral, inherit }