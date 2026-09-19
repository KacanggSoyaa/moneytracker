import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_transaction.dart';
import '../models/category.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final transactions = state.monthTransactions
        .where((t) => _filter == null || t.type == _filter)
        .toList();
    final grouped = _groupByDay(transactions);
    final symbol = state.settings.currencySymbol;

    return Column(
      children: [
        _MonthSelector(selected: state.selectedMonth),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<TransactionType?>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) =>
                  setState(() => _filter = selection.first),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: grouped.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long,
                  title: 'No transactions',
                  subtitle: _filter == null
                      ? 'Tap + to add transactions for this month.'
                      : 'No ${_filter!.name} transactions for this month.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  children: [
                    for (final day in grouped.keys) ...[
                      _DayHeader(
                        date: day,
                        transactions: grouped[day]!,
                        symbol: symbol,
                      ),
                      Card(
                        margin: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Column(
                          children: [
                            for (final tx in grouped[day]!)
                              TransactionTile(
                                transaction: tx,
                                category:
                                    state.categoryById[tx.categoryId] ??
                                        const Category(
                                          name: 'Other',
                                          type: TransactionType.expense,
                                          icon: 'category',
                                          color: 0xFF78909C,
                                        ),
                                currencySymbol: symbol,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TransactionFormScreen(initial: tx),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Map<DateTime, List<AppTransaction>> _groupByDay(
      List<AppTransaction> list) {
    final map = <DateTime, List<AppTransaction>>{};
    for (final tx in list) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selected;

  const _MonthSelector({required this.selected});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final label = DateFormat('MMMM yyyy').format(selected);
    return Row(
      children: [
        IconButton(
          onPressed: () =>
              state.setMonth(DateTime(selected.year, selected.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          onPressed: () =>
              state.setMonth(DateTime(selected.year, selected.month + 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final List<AppTransaction> transactions;
  final String symbol;

  const _DayHeader({
    required this.date,
    required this.transactions,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amountCents);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amountCents);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final label = date == today
        ? 'Today'
        : date == today.subtract(const Duration(days: 1))
            ? 'Yesterday'
            : DateFormat('EEEE, d MMM').format(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (income > 0)
            Text(
              '+${CurrencyFormatter.formatCents(income, symbol)}',
              style: TextStyle(
                fontSize: 12,
                color: scheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (income > 0 && expense > 0) const SizedBox(width: 8),
          if (expense > 0)
            Text(
              '-${CurrencyFormatter.formatCents(expense, symbol)}',
              style: TextStyle(
                fontSize: 12,
                color: scheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}