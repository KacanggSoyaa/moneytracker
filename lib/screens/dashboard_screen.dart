import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_carousel.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onSeeAllTransactions;
  final VoidCallback? onSeeAllInsights;

  const DashboardScreen({
    super.key,
    this.onSeeAllTransactions,
    this.onSeeAllInsights,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return RefreshIndicator(
      onRefresh: () => state.reloadMonth(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          MonthCarousel(
            selected: state.selectedMonth,
            onSelected: (m) => state.setMonth(m),
          ),
          const SizedBox(height: 12),
          _BalanceCard(state: state),
          const SizedBox(height: 16),
          if (_budgetSummaries(state).isNotEmpty) ...[
            _SectionHeader(
              title: 'Budget status',
              action: TextButton(
                onPressed: onSeeAllInsights,
                child: const Text('Insights'),
              ),
            ),
            const SizedBox(height: 4),
            Card(
              child: Column(
                children: [
                  for (final (category, planned, spent) in _budgetSummaries(state))
                    _BudgetRow(
                      category: category,
                      spent: spent,
                      planned: planned,
                      symbol: state.settings.currencySymbol,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (state.monthTransactions.isNotEmpty) ...[
            _SectionHeader(title: 'Top categories'),
            const SizedBox(height: 4),
            Card(
              child: Column(
                children: [
                  for (final (category, cents) in _topCategories(state))
                    _CategoryRow(
                      category: category,
                      cents: cents,
                      maxCents: _topCategories(state).first.$2,
                      symbol: state.settings.currencySymbol,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _SectionHeader(
            title: 'Recent transactions',
            trailing: state.monthTransactions.length > 4
                ? TextButton(onPressed: onSeeAllTransactions, child: const Text('See all'))
                : null,
          ),
          const SizedBox(height: 4),
          if (state.recentTransactions.isEmpty)
            Card(
              child: EmptyState(
                icon: Icons.wallet,
                title: 'No transactions yet',
                subtitle: 'Tap + to add your first expense or income.',
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final tx in state.recentTransactions.take(8))
                    TransactionTile(
                      transaction: tx,
                      category: state.categoryById[tx.categoryId] ??
                          const Category(
                            name: '—',
                            type: TransactionType.expense,
                            icon: 'category',
                            color: 0xFF78909C,
                          ),
                      currencySymbol: state.settings.currencySymbol,
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
      ),
    );
  }

  List<(Category, int, int)> _budgetSummaries(AppState state) {
    final result = <(Category, int, int)>[];
    for (final category in state.expenseCategories) {
      final budget = state.budgetByCategory[category.id];
      if (budget == null) continue;
      result.add((
        category,
        budget.monthlyAmountCents,
        state.spentForCategory(category.id!),
      ));
    }
    result.sort((a, b) => b.$3.compareTo(a.$3));
    return result.take(4).toList();
  }

  List<(Category, int)> _topCategories(AppState state) {
    final list = state.expenseCategories
        .map((c) => (c, state.spentForCategory(c.id!)))
        .where((e) => e.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(4).toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget? action;

  const _SectionHeader({required this.title, this.trailing, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        ?trailing,
        ?action,
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final AppState state;

  const _BalanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final symbol = state.settings.currencySymbol;
    final income = state.monthTotals[TransactionType.income] ?? 0;
    final expense = state.monthTotals[TransactionType.expense] ?? 0;
    final balance = income - expense;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.40),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.88),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${balance < 0 ? '-' : ''}$symbol${CurrencyFormatter.formatCents(balance.abs(), '')}',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _BalanceItem(
                      icon: Icons.arrow_downward,
                      iconColor: Colors.white,
                      label: 'Income',
                      value: CurrencyFormatter.formatCents(income, symbol),
                      valueColor: const Color(0xFFA6F1CC),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: scheme.onPrimary.withValues(alpha: 0.25),
                    ),
                    _BalanceItem(
                      icon: Icons.arrow_upward,
                      iconColor: Colors.white,
                      label: 'Expense',
                      value: CurrencyFormatter.formatCents(expense, symbol),
                      valueColor: const Color(0xFFFFB4B4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _BalanceItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final Category category;
  final int spent;
  final int planned;
  final String symbol;

  const _BudgetRow({
    required this.category,
    required this.spent,
    required this.planned,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = (spent / planned).clamp(0.0, 1.0);
    final over = spent > planned;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CategoryAvatar(category: category),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${formatCentsShort(spent, symbol)} / ${formatCentsShort(planned, symbol)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: over ? AppTheme.expenseRed : scheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: over ? AppTheme.expenseRed : scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatCentsShort(int cents, String symbol) =>
      cents >= 100000000 ? '$symbol${(cents / 100000000).toStringAsFixed(0)}M' : '$symbol${(cents / 100).toStringAsFixed(0)}';
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final int cents;
  final int maxCents;
  final String symbol;

  const _CategoryRow({
    required this.category,
    required this.cents,
    required this.maxCents,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = maxCents == 0 ? 0.0 : cents / maxCents;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
        children: [
          CategoryAvatar(category: category),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(fraction * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 12.5, color: scheme.outline),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 110,
            child: Text(
              CurrencyFormatter.formatCents(cents, symbol),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}