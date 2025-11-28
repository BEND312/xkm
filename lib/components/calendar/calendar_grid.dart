import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../entity/activity.dart';
import 'calendar_grid_item.dart';

class CalendarGrid extends HookWidget {
  CalendarGrid({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.activities,
    required this.onDateSelected,
    required this.showBadges,
    required this.getIsInEvent,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final List<Activity> activities;
  final Function(DateTime) onDateSelected;
  final bool showBadges;
  final bool Function(DateTime) getIsInEvent;

  final Map<String, List<DateTime>> _daysCache = {};

  List<DateTime> _getDaysInMonth() {
    final cacheKey = '${displayedMonth.year}-${displayedMonth.month}';
    if (_daysCache.containsKey(cacheKey)) {
      return _daysCache[cacheKey]!;
    }

    final DateTime firstDay =
        DateTime(displayedMonth.year, displayedMonth.month, 1);
    final int firstWeekday = firstDay.weekday;
    final List<DateTime> days = [];

    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }

    for (int i = 0; i < 31; i++) {
      final DateTime day = firstDay.add(Duration(days: i));
      if (day.month == displayedMonth.month) {
        days.add(day);
      }
    }

    while (days.length < 42) {
      days.add(days.last.add(const Duration(days: 1)));
    }

    _daysCache[cacheKey] = days;
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = useMemoized(() => _getDaysInMonth(), [displayedMonth]);

    return Column(
      children: [
        _buildWeekdaysRow(),
        const SizedBox(height: 8),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              return true;
            },
            child: RepaintBoundary(
              child: GridView.builder(
                key: const PageStorageKey('calendar_grid'),
                padding: EdgeInsets.zero,
                cacheExtent: 1000,
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  return CalendarGridItem(
                    key: ValueKey('grid_item_${date.toString()}'),
                    date: date,
                    displayedMonth: displayedMonth,
                    selectedDate: selectedDate,
                    activities: activities,
                    onDateSelected: onDateSelected,
                    showBadges: showBadges,
                    getIsInEvent: getIsInEvent,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdaysRow() => const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('一'),
          Text('二'),
          Text('三'),
          Text('四'),
          Text('五'),
          Text('六', style: TextStyle(color: Colors.green)),
          Text('日', style: TextStyle(color: Colors.green)),
        ],
      );
}
