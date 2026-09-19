import 'package:flutter/material.dart';

import '../models/app_transaction.dart';
import '../models/category.dart';
import 'amount_text.dart';
import 'category_avatar.dart';

class TransactionTile extends StatelessWidget {
  final AppTransaction transaction;
  final Category category;
  final String currencySymbol;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.currencySymbol,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isExpense = transaction.type == TransactionType.expense;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CategoryAvatar(category: category),
      title: Text(
        category.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        transaction.note == null || transaction.note!.isEmpty
            ? _dayLabel(transaction.date)
            : '${transaction.note}  ·  ${_dayLabel(transaction.date)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, color: scheme.outline),
      ),
      trailing: AmountText(
        cents: transaction.amountCents,
        symbol: currencySymbol,
        color: isExpense ? TransactionColor.expense : TransactionColor.income,
        fontSize: 15,
      ),
    );
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day} ${_monthAbbr(date.month)}';
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _monthAbbr(int month) => _months[month - 1];