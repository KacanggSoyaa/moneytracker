import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_transaction.dart';
import '../models/budget.dart';
import '../models/category.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'moneytracker.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income','expense')),
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK (type IN ('income','expense')),
        amount_cents INTEGER NOT NULL,
        category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_tx_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_tx_category ON transactions(category_id)');
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL UNIQUE REFERENCES categories(id) ON DELETE CASCADE,
        monthly_amount_cents INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');

    final now = DateTime.now().toUtc().toIso8601String();
    final batch = db.batch();
    var order = 0;
    for (final c in defaultCategories) {
      batch.insert(
        'categories',
        {...c.toMap(), 'is_default': 1, 'sort_order': order++},
      );
    }
    await batch.commit(noResult: true);
    await _seedSettings(db, now);
  }

  Future<void> _seedSettings(Database db, String now) async {
    await db.insert('settings', {'key': 'created_at', 'value': now});
  }

  static const List<Category> defaultCategories = [
    Category(name: 'Salary', type: TransactionType.income, icon: 'payments', color: 0xFF2E7D32),
    Category(name: 'Freelance', type: TransactionType.income, icon: 'work', color: 0xFF00897B),
    Category(name: 'Investment', type: TransactionType.income, icon: 'trending_up', color: 0xFF5C6BC0),
    Category(name: 'Gifts', type: TransactionType.income, icon: 'card_giftcard', color: 0xFFD81B60),
    Category(name: 'Savings', type: TransactionType.income, icon: 'savings', color: 0xFF00838F),
    Category(name: 'Other Income', type: TransactionType.income, icon: 'attach_money', color: 0xFF546E7A),
    Category(name: 'Food & Dining', type: TransactionType.expense, icon: 'restaurant', color: 0xFFE53935),
    Category(name: 'Groceries', type: TransactionType.expense, icon: 'shopping_cart', color: 0xFFFB8C00),
    Category(name: 'Transport', type: TransactionType.expense, icon: 'directions_bus', color: 0xFF1E88E5),
    Category(name: 'Housing', type: TransactionType.expense, icon: 'home', color: 0xFF8D6E63),
    Category(name: 'Utilities', type: TransactionType.expense, icon: 'bolt', color: 0xFFFFB300),
    Category(name: 'Health', type: TransactionType.expense, icon: 'health_and_safety', color: 0xFF00ACC1),
    Category(name: 'Entertainment', type: TransactionType.expense, icon: 'sports_esports', color: 0xFF8E24AA),
    Category(name: 'Shopping', type: TransactionType.expense, icon: 'shopping_bag', color: 0xFFEC407A),
    Category(name: 'Education', type: TransactionType.expense, icon: 'school', color: 0xFF5E35B1),
    Category(name: 'Travel', type: TransactionType.expense, icon: 'flight_takeoff', color: 0xFF43A047),
    Category(name: 'Other', type: TransactionType.expense, icon: 'category', color: 0xFF78909C),
  ];

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'type, sort_order, name');
    return rows.map(Category.fromMap).toList();
  }

  Future<Category> insertCategory(Category category) async {
    final db = await database;
    final id = await db.insert('categories', {
      ...category.toMap(),
      'is_default': category.isDefault ? 1 : 0,
      'sort_order': await _nextSortOrder(db, category.type),
    });
    return Category(
      id: id,
      name: category.name,
      type: category.type,
      icon: category.icon,
      color: category.color,
    );
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countTransactionsForCategory(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM transactions WHERE category_id = ?',
      [categoryId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> _nextSortOrder(Database db, TransactionType type) async {
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next FROM categories WHERE type = ?',
      [type.dbValue],
    );
    return (result.first['next'] as int);
  }

  Future<AppTransaction> insertTransaction(AppTransaction tx) async {
    final db = await database;
    final id = await db.insert('transactions', tx.toMap());
    return AppTransaction(
      id: id,
      type: tx.type,
      amountCents: tx.amountCents,
      categoryId: tx.categoryId,
      note: tx.note,
      date: tx.date,
      createdAt: tx.createdAt,
    );
  }

  Future<void> updateTransaction(AppTransaction tx) async {
    final db = await database;
    await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AppTransaction>> getTransactionsInMonth(
      int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final end = DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);
    final rows = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(AppTransaction.fromMap).toList();
  }

  Future<List<AppTransaction>> getRecentTransactions(int limit) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return rows.map(AppTransaction.fromMap).toList();
  }

  Future<List<AppTransaction>> getAllTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return rows.map(AppTransaction.fromMap).toList();
  }

  Future<Map<TransactionType, int>> getMonthTotals(
      int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final end = DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);
    final rows = await db.rawQuery(
      'SELECT type, SUM(amount_cents) AS total FROM transactions '
      'WHERE date BETWEEN ? AND ? GROUP BY type',
      [start, end],
    );
    final result = <TransactionType, int>{
      TransactionType.income: 0,
      TransactionType.expense: 0,
    };
    for (final row in rows) {
      final type = TransactionType.fromDb(row['type'] as String);
      result[type] = (row['total'] as int?) ?? 0;
    }
    return result;
  }

  Future<Map<int, int>> getCategoryTotalsInMonth(
      int year, int month, TransactionType type) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final end = DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);
    final rows = await db.rawQuery(
      'SELECT category_id, SUM(amount_cents) AS total FROM transactions '
      'WHERE date BETWEEN ? AND ? AND type = ? GROUP BY category_id',
      [start, end, type.dbValue],
    );
    return {
      for (final row in rows) row['category_id'] as int: row['total'] as int,
    };
  }

  Future<Map<String, Map<TransactionType, int>>> getMonthlyHistory(
      DateTime from) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT substr(date, 1, 7) AS month, type, SUM(amount_cents) AS total '
      'FROM transactions WHERE date >= ? GROUP BY month, type',
      [_ymd(from)],
    );
    final result = <String, Map<TransactionType, int>>{};
    for (final row in rows) {
      final month = row['month'] as String;
      final type = TransactionType.fromDb(row['type'] as String);
      result.putIfAbsent(month, () => {
            TransactionType.income: 0,
            TransactionType.expense: 0,
          })[type] = row['total'] as int;
    }
    return result;
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final rows = await db.query('budgets');
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> upsertBudget(Budget budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBudget(int categoryId) async {
    final db = await database;
    await db.delete('budgets', where: 'category_id = ?', whereArgs: [categoryId]);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings',
        where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _ymd(DateTime d) => d.toIso8601String().substring(0, 10);
}