class Budget {
  final int? id;
  final int categoryId;
  final int monthlyAmountCents;

  const Budget({
    this.id,
    required this.categoryId,
    required this.monthlyAmountCents,
  });

  factory Budget.fromMap(Map<String, Object?> map) => Budget(
        id: map['id'] as int,
        categoryId: map['category_id'] as int,
        monthlyAmountCents: map['monthly_amount_cents'] as int,
      );

  Map<String, Object?> toMap() => {
        'category_id': categoryId,
        'monthly_amount_cents': monthlyAmountCents,
      };

  Budget copyWith({int? monthlyAmountCents}) => Budget(
        id: id,
        categoryId: categoryId,
        monthlyAmountCents: monthlyAmountCents ?? this.monthlyAmountCents,
      );
}