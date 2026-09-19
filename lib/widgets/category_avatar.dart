import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/icon_lookup.dart';

class CategoryAvatar extends StatelessWidget {
  final Category category;
  final double radius;

  const CategoryAvatar({
    super.key,
    required this.category,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconFromName(category.icon),
        color: color,
        size: radius * 1.1,
      ),
    );
  }
}