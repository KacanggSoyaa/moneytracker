import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/app_settings.dart';
import '../models/app_transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../utils/date_utils.dart' as du;

class AppState extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  bool initialized = false;

  List<Category> categories = [];
  Map<int, Category> categoryById = {};
  List<AppTransaction> monthTransactions = [];
  List<AppTransaction> recentTransactions = [];
  Map<TransactionType, int> monthTotals = {
    TransactionType.income: 0,
    TransactionType.expense: 0,
  };
  Map<int, int> categoryTotals = {};
  List<Budget> budgets = [];
  Map<String, Map<TransactionType, int>> monthlyHistory = {};
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  AppSettings settings = const AppSettings();

  List<Category> get incomeCategories =>
      categories.where((c) => c.type == TransactionType.income).toList();

  List<Category> get expenseCategories =>
      categories.where((c) => c.type == TransactionType.expense).toList();

  int get balanceCents =>
      monthTotals[TransactionType.income]! - monthTotals[TransactionType.expense]!;

  Map<int, Budget> get budgetByCategory =>
      {for (final b in budgets) b.categoryId: b};

  Future<void> initialize() async {
    if (initialized) return;
    await refresh();
    initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    categories = await _db.getCategories();
    categoryById = {for (final c in categories) c.id! : c};
    budgets = await _db.getBudgets();
    settings = await _loadSettings();
    await reloadMonth();
    recentTransactions = await _db.getRecentTransactions(8);
    monthlyHistory =
        await _db.getMonthlyHistory(du.lastMonths(selectedMonth, 6).first);
    notifyListeners();
  }

  Future<AppSettings> _loadSettings() async {
    final currency = await _db.getSetting(AppSettings.currencyKey);
    final theme = await _db.getSetting(AppSettings.themeKey);
    return AppSettings.fromMap({
      AppSettings.currencyKey: currency,
      AppSettings.themeKey: theme,
    });
  }

  Future<void> reloadMonth() async {
    final monthTotals = await _db.getMonthTotals(
        selectedMonth.year, selectedMonth.month);
    final categoryTotals = await _db.getCategoryTotalsInMonth(
        selectedMonth.year, selectedMonth.month, TransactionType.expense);
    final monthTransactions = await _db.getTransactionsInMonth(
        selectedMonth.year, selectedMonth.month);
    this.monthTotals = monthTotals;
    this.categoryTotals = categoryTotals;
    this.monthTransactions = monthTransactions;
    notifyListeners();
  }

  Future<void> setMonth(DateTime month) async {
    selectedMonth = DateTime(month.year, month.month);
    await reloadMonth();
  }

  Future<void> addTransaction({
    required TransactionType type,
    required int amountCents,
    required int categoryId,
    String? note,
    required DateTime date,
  }) async {
    await _db.insertTransaction(AppTransaction(
      type: type,
      amountCents: amountCents,
      categoryId: categoryId,
      note: note,
      date: date,
      createdAt: DateTime.now(),
    ));
    await refresh();
  }

  Future<void> updateTransaction(AppTransaction transaction) async {
    await _db.updateTransaction(transaction);
    await refresh();
  }

  Future<void> deleteTransaction(AppTransaction transaction) async {
    await _db.deleteTransaction(transaction.id!);
    await refresh();
  }

  Future<void> addCategory(Category category) async {
    await _db.insertCategory(category);
    await refresh();
  }

  Future<void> updateCategory(Category category) async {
    await _db.updateCategory(category);
    await refresh();
  }

  Future<void> deleteCategory(Category category) async {
    final count = await _db.countTransactionsForCategory(category.id!);
    if (count > 0) {
      throw StateError(
          'Cannot delete "$category.name": $count transaction(s) use it.');
    }
    await _db.deleteCategory(category.id!);
    await refresh();
  }

  Future<void> setBudgetForCategory(int categoryId, int monthlyCents) async {
    if (monthlyCents <= 0) {
      await _db.deleteBudget(categoryId);
    } else {
      await _db.upsertBudget(
          Budget(categoryId: categoryId, monthlyAmountCents: monthlyCents));
    }
    await refresh();
  }

  Future<void> setCurrencySymbol(String symbol) async {
    await _db.setSetting(AppSettings.currencyKey, symbol);
    await refresh();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _db.setSetting(AppSettings.themeKey, AppSettings.themeToString(mode));
    await refresh();
  }

  int spentForCategory(int categoryId) => categoryTotals[categoryId] ?? 0;

  double budgetProgress(int categoryId) {
    final budget = budgetByCategory[categoryId];
    if (budget == null || budget.monthlyAmountCents <= 0) return 0;
    return (spentForCategory(categoryId) / budget.monthlyAmountCents).clamp(0.0, 1.0);
  }

  bool isOverBudget(int categoryId) =>
      budgetByCategory[categoryId] != null &&
      budgetByCategory[categoryId]!.monthlyAmountCents > 0 &&
      spentForCategory(categoryId) > budgetByCategory[categoryId]!.monthlyAmountCents;
}