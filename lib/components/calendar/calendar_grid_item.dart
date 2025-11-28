import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

import '../../entity/activity.dart';
import '../../entity/activity_type.dart';
import '../../entity/date_data.dart';
import 'date_cell.dart';

class CalendarGridItem extends HookWidget {
  const CalendarGridItem({
    super.key,
    required this.date,
    required this.displayedMonth,
    required this.selectedDate,
    required this.activities,
    required this.onDateSelected,
    required this.showBadges,
    required this.getIsInEvent,
  });

  final DateTime date;
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final List<Activity> activities;
  final Function(DateTime) onDateSelected;
  final bool showBadges;
  final bool Function(DateTime) getIsInEvent;

  @override
  Widget build(BuildContext context) {
    final dateData = useMemoized(() {
      final isCurrentMonth = date.month == displayedMonth.month;
      final isWeekend = date.weekday >= 6;
      final isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;

      final activityMatched = activities
          .where((activity) => activity.isInActivity(date))
          .toList()
        ..sort((a, b) => ActivityTypeData.of(b.type)
            .priority
            .compareTo(ActivityTypeData.of(a.type).priority));

      final activity = activityMatched.firstOrNull;
      final isActivity = activity != null && activityMatched.isNotEmpty;
      final isHoliday = (!isActivity && isWeekend) ||
          (isActivity && activity.holiday) ||
          (isWeekend && isActivity && !activity.holiday && activity.isShift);
      final noDisplay = activityMatched.where((ac) => ac.display).isEmpty ||
          activity?.type == ActivityType.hidden;
      final isInEvent = getIsInEvent(date);

      return DateData(
        date: date,
        isCurrentMonth: isCurrentMonth,
        isWeekend: isWeekend,
        isSelected: isSelected,
        isActivity: isActivity,
        isHoliday: isHoliday,
        isInEvent: isInEvent,
        noDisplay: noDisplay,
        activityMatched: activityMatched,
        activity: activity,
      );
    }, [date, displayedMonth, selectedDate, activities]);

    return RepaintBoundary(
      child: GestureDetector(
        key: Key(
          dateData.activity?.hashCode.toString() ??
              date.millisecondsSinceEpoch.toString(),
        ),
        onTap: () => onDateSelected(date),
        child: DateCell(
          dateData: dateData,
          showBadges: showBadges,
          bg: context.theme.colorScheme.background,
          fg: context.theme.colorScheme.foreground,
        ),
      ),
    );
  }
}
