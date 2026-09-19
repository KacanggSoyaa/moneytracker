import 'category.dart';

class AppTransaction {
  final int? id;
  final TransactionType type;
  final int amountCents;
  final int categoryId;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const AppTransaction({
    this.id,
    required this.type,
    required this.amountCents,
    required this.categoryId,
    this.note,
    required this.date,
    required this.createdAt,
  });

  double get amount => amountCents / 100;

  factory AppTransaction.fromMap(Map<String, Object?> map) => AppTransaction(
        id: map['id'] as int,
        type: TransactionType.fromDb(map['type'] as String),
        amountCents: map['amount_cents'] as int,
        categoryId: map['category_id'] as int,
        note: map['note'] as String?,
        date: DateTime.parse(map['date'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        'type': type.dbValue,
        'amount_cents': amountCents,
        'category_id': categoryId,
        'note': note,
        'date': date.toIso8601String().substring(0, 10),
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  AppTransaction copyWith({
    TransactionType? type,
    int? amountCents,
    int? categoryId,
    String? note,
    DateTime? date,
  }) =>
      AppTransaction(
        id: id,
        type: type ?? this.type,
        amountCents: amountCents ?? this.amountCents,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        date: date ?? this.date,
        createdAt: createdAt,
      );
}