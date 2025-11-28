import 'package:hive/hive.dart';
import 'package:swustmeow/entity/base_event.dart';
import 'package:swustmeow/utils/time.dart';

import 'date_type.dart';

part 'calendar_event.g.dart';

@HiveType(typeId: 0)
class CalendarEvent implements BaseEvent {
  const CalendarEvent(
      {required this.eventId,
      required this.calendarId,
      required this.title,
      this.description,
      required this.start,
      required this.end,
      this.allDay = false,
      this.location});

  @HiveField(0)
  final String eventId;

  @HiveField(1)
  final String calendarId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final DateTime? start;

  @HiveField(5)
  final DateTime? end;

  @HiveField(6)
  final bool allDay;

  @HiveField(7)
  final String? location;

  bool isInEvent(DateTime date) {
    if (start != null && end != null) return isYMDInRange(date, start!, end!);

    if (start != null && end == null) {
      return date.yearMonthDayEquals(start!) || date.isAfter(start!);
    }

    if (start == null && end != null) {
      return date.yearMonthDayEquals(end!) || date.isBefore(end!);
    }

    return false;
  }

  @override
  String? getName() => title;

  @override
  DateTime? getStart(DateTime date) => start;

  @override
  DateTime? getEnd(DateTime date) => end;

  @override
  DateType getType(DateTime date) {
    final start = getStart(date);
    final end = getEnd(date);
    if (start == null || end == null) return DateType.singleYMD;
    return start.yearMonthDayEquals(end)
        ? DateType.singleYMD
        : DateType.staticYMDRange;
  }
}
