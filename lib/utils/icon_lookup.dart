import 'package:flutter/material.dart';

const Map<String, IconData> _icons = {
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'local_bar': Icons.local_bar,
  'directions_bus': Icons.directions_bus,
  'directions_car': Icons.directions_car,
  'train': Icons.train,
  'shopping_cart': Icons.shopping_cart,
  'shopping_bag': Icons.shopping_bag,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'home': Icons.home,
  'school': Icons.school,
  'flight_takeoff': Icons.flight_takeoff,
  'health_and_safety': Icons.health_and_safety,
  'favorite': Icons.favorite,
  'pets': Icons.pets,
  'sports_esports': Icons.sports_esports,
  'movie': Icons.movie,
  'music_note': Icons.music_note,
  'local_phone': Icons.local_phone,
  'wifi': Icons.wifi,
  'smartphone': Icons.smartphone,
  'child_care': Icons.child_care,
  'payments': Icons.payments,
  'work': Icons.work,
  'money': Icons.money,
  'trending_up': Icons.trending_up,
  'storefront': Icons.storefront,
  'savings': Icons.savings,
  'card_giftcard': Icons.card_giftcard,
  'attach_money': Icons.attach_money,
  'local_offer': Icons.local_offer,
  'category': Icons.category,
  'more_horiz': Icons.more_horiz,
  'shopping_cart_outlined': Icons.shopping_cart_outlined,
  'fitness_center': Icons.fitness_center,
  'self_improvement': Icons.self_improvement,
};

IconData iconFromName(String name) => _icons[name] ?? Icons.category;

List<IconData> availableIcons() => _icons.values.toList()..sort((a, b) {
      final ai = a.codePoint;
      final bi = b.codePoint;
      return ai.compareTo(bi);
    });

String? iconNameFor(IconData icon) => _icons.entries
    .where((e) => e.value.codePoint == icon.codePoint)
    .map((e) => e.key)
    .firstOrNull;