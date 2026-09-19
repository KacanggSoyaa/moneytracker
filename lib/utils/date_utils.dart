String isoDay(DateTime date) => date.toIso8601String().substring(0, 10);

String monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

DateTime monthStart(DateTime date) => DateTime(date.year, date.month);

DateTime firstDayOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

DateTime lastDayOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);

List<DateTime> lastMonths(DateTime reference, int count) =>
    List.generate(
      count,
      (i) => DateTime(reference.year, reference.month - (count - 1 - i)),
    );