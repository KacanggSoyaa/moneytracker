import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Horizontally swipeable month carousel.
///
/// Pages span ±5 years around the real current month inclusive-the "today"
/// page anchors in the middle. Swiping (or a tap with inertial physics)
/// moves the selected month. The widget tracks external changes to
/// [selected] and snaps back to them via [PageController.jumpToPage].
class MonthCarousel extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  const MonthCarousel({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<MonthCarousel> createState() => _MonthCarouselState();
}

class _MonthCarouselState extends State<MonthCarousel> {
  static const int _spanYears = 5;
  static const int _pageCount = _spanYears * 12 * 2 + 1;
  static const int _center = _spanYears * 12;

  late final PageController _controller;
  late DateTime _today;

  int get _currentIndex =>
      _center + (widget.selected.year - _today.year) * 12 +
      (widget.selected.month - _today.month);

  @override
  void initState() {
    super.initState();
    _today = DateTime(DateTime.now().year, DateTime.now().month);
    _controller = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.82,
    );
  }

  @override
  void didUpdateWidget(MonthCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _controller.jumpToPage(_currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    DateTime monthAt(int index) =>
        DateTime(_today.year, _today.month + (index - _center));

    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.9),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0x33FFFFFF), Color(0x1FFFFFFF)]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.6),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: PageView.builder(
          controller: _controller,
          onPageChanged: (page) => widget.onSelected(monthAt(page)),
          itemCount: _pageCount,
          itemBuilder: (context, index) {
            final month = monthAt(index);
            final isCurrent =
                month.year == _today.year && month.month == _today.month;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delta =
                    (_controller.page ?? _currentIndex.toDouble()) - index;
                final proximity = delta.abs().clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 1.0 - 0.06 * proximity,
                  child: Opacity(
                    opacity: 1.0 - 0.35 * proximity,
                    child: child,
                  ),
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMMM').format(month),
                      style: TextStyle(
                        fontSize: isCurrent ? 15 : 14,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${month.year}',
                      style: TextStyle(fontSize: 11, color: scheme.outline),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
