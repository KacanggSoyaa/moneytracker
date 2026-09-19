import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/category.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_utils.dart' as du;
import '../widgets/category_avatar.dart';
import '../widgets/empty_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Budgets'),
            ],
          ),
          const SizedBox(height: 4),
          const Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(),
                _BudgetsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final symbol = state.settings.currencySymbol;
    final months = du.lastMonths(state.selectedMonth, 6);
    final budgetBarColor = Theme.of(context).colorScheme.primary;
    final totalExpense = state.categoryTotals.values.fold(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.incomeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Income',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: budgetBarColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Expense',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: _maxYFor(months, state.monthlyHistory),
                      barGroups: [
                        for (var i = 0; i < months.length; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 3,
                            barRods: [
                              BarChartRodData(
                                toY: _incomeFor(months[i], state.monthlyHistory) /
                                    100,
                                width: 12,
                                color: AppTheme.incomeGreen,
                                borderRadius:
                                    const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                              ),
                              BarChartRodData(
                                toY: _expenseFor(months[i], state.monthlyHistory) /
                                    100,
                                width: 12,
                                color: budgetBarColor,
                                borderRadius:
                                    const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                              ),
                            ],
                          ),
                      ],
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            getTitlesWidget: (value, meta) =>
                                Text(
                              _compactY((value * 100).round()),
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= months.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat.MMM().format(months[index]),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(enabled: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Where your money went — ${DateFormat('MMMM yyyy').format(state.selectedMonth)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        if (totalExpense == 0)
          const Card(
            child: EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No spending yet',
              subtitle: 'Add expenses to see the breakdown.',
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 46,
                        sections: _pieSections(state, symbol),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final (category, cents) in _sortedExpenseCategories(state))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CategoryAvatar(category: category, radius: 14),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${(cents / totalExpense * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: Text(
                              CurrencyFormatter.formatCents(cents, symbol),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  double _incomeFor(DateTime m, Map<String, Map<TransactionType, int>> history) =>
      (history[du.monthKey(m)]?[TransactionType.income] ?? 0).toDouble();

  double _expenseFor(DateTime m, Map<String, Map<TransactionType, int>> history) =>
      (history[du.monthKey(m)]?[TransactionType.expense] ?? 0).toDouble();

  double _maxYFor(
      List<DateTime> months, Map<String, Map<TransactionType, int>> history) {
    var max = 0.0;
    for (final m in months) {
      max = math.max(max, _incomeFor(m, history));
      max = math.max(max, _expenseFor(m, history));
    }
    final padded = max * 1.2;
    return padded <= 0 ? 100 : padded / 100;
  }

  List<(Category, int)> _sortedExpenseCategories(AppState state) {
    final list = state.expenseCategories
        .map((c) => (c, state.spentForCategory(c.id!)))
        .where((e) => e.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return list;
  }

  List<PieChartSectionData> _pieSections(AppState state, String symbol) {
    final entries = _sortedExpenseCategories(state);
    final total = state.categoryTotals.values.fold(0, (a, b) => a + b);
    if (total == 0) return const [];
    return [
      for (final (category, cents) in entries)
        PieChartSectionData(
          value: cents.toDouble(),
          color: Color(category.color),
          radius: 52,
          title: '${(cents / total * 100).toStringAsFixed(0)}%',
          titleStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _contrastFor(Color(category.color)),
          ),
        ),
    ];
  }

  Color _contrastFor(Color color) =>
      color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

  String _compactY(int cents) {
    final value = cents ~/ 100;
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toString();
  }
}

class _BudgetsTab extends StatelessWidget {
  const _BudgetsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final symbol = state.settings.currencySymbol;
    final withBudget = state.expenseCategories
        .where((c) => state.budgetByCategory.containsKey(c.id))
        .toList();
    final withoutBudget = state.expenseCategories
        .where((c) => !state.budgetByCategory.containsKey(c.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        if (withBudget.isEmpty)
          const Card(
            child: EmptyState(
              icon: Icons.savings_outlined,
              title: 'No budgets set',
              subtitle: 'Set a monthly limit per category to stay on track.',
            ),
          )
        else
          for (final category in withBudget)
            _BudgetCard(
              category: category,
              spent: state.spentForCategory(category.id!),
              planned: state.budgetByCategory[category.id!]!.monthlyAmountCents,
              symbol: symbol,
              onEdit: () => _openBudgetDialog(context, category),
            ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Add a budget',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final category in withoutBudget)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: CategoryAvatar(category: category),
            title: Text(
              category.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _openBudgetDialog(context, category),
            ),
            onTap: () => _openBudgetDialog(context, category),
          ),
      ],
    );
  }

  Future<void> _openBudgetDialog(
      BuildContext context, Category category) async {
    final budget = context.read<AppState>().budgetByCategory[category.id];
    final controller = TextEditingController(
      text: budget == null
          ? ''
          : CurrencyFormatter.formatCents(budget.monthlyAmountCents, ''),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${budget == null ? 'Set' : 'Edit'} budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CategoryAvatar(category: category, radius: 22),
                const SizedBox(width: 10),
                Text(
                  category.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Monthly limit',
                prefixText: '${context.read<AppState>().settings.currencySymbol} ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (budget != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(0),
              child: Text(
                'Remove',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              CurrencyFormatter.parseCentsFromInput(controller.text),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final saved = result;
    if (context.mounted) {
      await context.read<AppState>().setBudgetForCategory(category.id!, saved);
    }
  }
}

class _BudgetCard extends StatelessWidget {
  final Category category;
  final int spent;
  final int planned;
  final String symbol;
  final VoidCallback onEdit;

  const _BudgetCard({
    required this.category,
    required this.spent,
    required this.planned,
    required this.symbol,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final over = spent > planned;
    final ratio = planned <= 0 ? 0.0 : (spent / planned).clamp(0.0, 1.2);
    final progressColor = over ? AppTheme.expenseRed : AppTheme.seed;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryAvatar(category: category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit budget',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatCents(spent, symbol),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: over ? AppTheme.expenseRed : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 6),
                    child: Text(
                      'of ${CurrencyFormatter.formatCents(planned, symbol)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(spent / planned * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: over
                          ? AppTheme.expenseRed
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: progressColor,
                ),
              ),
              if (over) ...[
                const SizedBox(height: 8),
                Text(
                  'Over budget by ${CurrencyFormatter.formatCents(spent - planned, symbol)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.expenseRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}