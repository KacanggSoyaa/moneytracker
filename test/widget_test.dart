import 'package:flutter_test/flutter_test.dart';

import 'package:moneytracker/utils/currency_formatter.dart';
import 'package:moneytracker/utils/icon_lookup.dart';
import 'package:moneytracker/utils/date_utils.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formatCents pads decimals and groups thousands', () {
      expect(CurrencyFormatter.formatCents(0, r'$'), r'$0.00');
      expect(CurrencyFormatter.formatCents(1099, r'$'), r'$10.99');
      expect(CurrencyFormatter.formatCents(123456789, r'$'), r'$1,234,567.89');
      expect(CurrencyFormatter.formatCents(-500, r'$'), r'-$5.00');
    });

    test('formatCompactCents shortens large values', () {
      expect(CurrencyFormatter.formatCompactCents(12345600, r'$'), r'$123K');
      expect(CurrencyFormatter.formatCompactCents(99999, r'$'), r'$999.99');
    });

    test('parseCentsFromInput handles decimals and plain numbers', () {
      expect(CurrencyFormatter.parseCentsFromInput('45'), 4500);
      expect(CurrencyFormatter.parseCentsFromInput('45.25'), 4525);
      expect(CurrencyFormatter.parseCentsFromInput('1.'), 100);
      expect(CurrencyFormatter.parseCentsFromInput('.5'), 50);
      expect(CurrencyFormatter.parseCentsFromInput(''), 0);
      expect(CurrencyFormatter.parseCentsFromInput('0.001'), 0);
    });
  });

  group('IconLookup', () {
    test('known icon names resolve', () {
      expect(iconFromName('restaurant'), isNotNull);
      expect(iconFromName('payments'), isNotNull);
    });

    test('unknown icon names fall back to category', () {
      expect(iconFromName('does_not_exist'), iconFromName('category'));
    });

    test('iconNameFor finds the name back', () {
      expect(iconNameFor(iconFromName('shopping_cart')), 'shopping_cart');
    });
  });

  group('DateUtils', () {
    test('monthKey formats month', () {
      expect(monthKey(DateTime(2024, 3, 5)), '2024-03');
      expect(monthKey(DateTime(2024, 11, 7)), '2024-11');
    });

    test('lastMonths returns the right months', () {
      final months = lastMonths(DateTime(2024, 3, 5), 6);
      expect(months.map(monthKey), [
        '2023-10',
        '2023-11',
        '2023-12',
        '2024-01',
        '2024-02',
        '2024-03',
      ]);
    });

    test('sameMonth compares years and months', () {
      expect(sameMonth(DateTime(2024, 1, 31), DateTime(2024, 1, 1)), isTrue);
      expect(sameMonth(DateTime(2024, 1, 1), DateTime(2024, 2, 1)), isFalse);
      expect(sameMonth(DateTime(2024, 1, 1), DateTime(2023, 1, 1)), isFalse);
    });
  });
}