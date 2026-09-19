enum TransactionType {
  income,
  expense;

  String get dbValue => name;

  static TransactionType fromDb(String value) =>
      value == 'income' ? TransactionType.income : TransactionType.expense;
}

class Category {
  final int? id;
  final String name;
  final TransactionType type;
  final String icon;
  final int color;
  final bool isDefault;
  final int sortOrder;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as int,
        name: map['name'] as String,
        type: TransactionType.fromDb(map['type'] as String),
        icon: map['icon'] as String,
        color: map['color'] as int,
        isDefault: (map['is_default'] as int) == 1,
        sortOrder: map['sort_order'] as int,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'type': type.dbValue,
        'icon': icon,
        'color': color,
        'is_default': isDefault ? 1 : 0,
        'sort_order': sortOrder,
      };

  Category copyWith({String? name, String? icon, int? color}) => Category(
        id: id,
        name: name ?? this.name,
        type: type,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        isDefault: isDefault,
        sortOrder: sortOrder,
      );
}