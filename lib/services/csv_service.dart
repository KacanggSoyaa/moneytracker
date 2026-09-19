import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../data/app_database.dart';
import '../models/app_transaction.dart';
import '../models/category.dart';
import 'save_backup.dart';

class CsvService {
  static Future<String?> export(AppDatabase db) async {
    final transactions = await db.getAllTransactions();
    final sb = StringBuffer();
    sb.writeln('type,amount_cents,category_id,note,date,created_at');
    for (final t in transactions) {
      final note = _escapeCsv(t.note ?? '');
      sb.writeln(
          '${t.type.dbValue},${t.amountCents},${t.categoryId},$note,${_ymd(t.date)},${t.createdAt.toIso8601String()}');
    }
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-');
    final fileName = 'moneytracker_backup_$stamp.csv';
    final bytes = Uint8List.fromList(utf8.encode(sb.toString()));
    final path = await saveBackupFile(fileName, bytes);
    if (path != null) return path;
    final uri = await FilePicker.saveFile(fileName: fileName, bytes: bytes);
    if (uri == null) return null;
    return uri.toString();
  }

  static Future<ImportResult> import(AppDatabase db, Uint8List bytes) async {
    final content = utf8.decode(bytes);
    final lines = content.trim().split('\n');
    if (lines.isEmpty) return const ImportResult(0, 0);

    final categories = await db.getCategories();
    final incomeFallback = categories.firstWhere(
      (c) => c.type == TransactionType.income,
      orElse: () => categories.first,
    );
    final expenseFallback = categories.firstWhere(
      (c) => c.type == TransactionType.expense,
      orElse: () => categories.first,
    );

    var imported = 0;
    var skipped = 0;
    for (final line in lines.skip(1)) {
      final row = _splitCsv(line);
      if (row.length < 6) {
        skipped++;
        continue;
      }
      final type = TransactionType.fromDb(row[0]);
      final amountCents = int.tryParse(row[1]);
      final categoryId = int.tryParse(row[2]);
      final byId = categories.where((c) => c.id == categoryId).firstOrNull;
      final category =
          byId ?? (type == TransactionType.income ? incomeFallback : expenseFallback);
      final note = row[3].isEmpty ? null : row[3];
      final date = DateTime.tryParse(row[4]);
      if (amountCents == null || amountCents <= 0 || date == null) {
        skipped++;
        continue;
      }
      final createdAt = DateTime.tryParse(row[5]) ?? date;
      await db.insertTransaction(AppTransaction(
        type: type,
        amountCents: amountCents,
        categoryId: category.id!,
        note: note,
        date: date,
        createdAt: createdAt,
      ));
      imported++;
    }
    return ImportResult(imported, skipped);
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static List<String> _splitCsv(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          current.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString());
    return result;
  }

  static String _ymd(DateTime d) => d.toIso8601String().substring(0, 10);
}

class ImportResult {
  final int imported;
  final int skipped;

  const ImportResult(this.imported, this.skipped);
}