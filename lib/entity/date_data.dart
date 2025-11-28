import 'activity.dart';

class DateData {
  const DateData(
      {required this.date,
      required this.isCurrentMonth,
      required this.isWeekend,
      required this.isSelected,
      required this.isActivity,
      required this.isHoliday,
      required this.isInEvent,
      required this.noDisplay,
      required this.activityMatched,
      required this.activity});

  final DateTime date;
  final bool isCurrentMonth;
  final bool isWeekend;
  final bool isSelected;
  final bool isActivity;
  final bool isHoliday;
  final bool isInEvent;
  final bool noDisplay;
  final List<Activity> activityMatched;
  final Activity? activity;
}
