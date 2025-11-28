import 'package:flutter/material.dart';
import 'package:lunar/calendar/Lunar.dart';
import 'package:lunar/calendar/Solar.dart';

bool hmAfter(String a, String b) {
  final [aH, aM] = a.split(':').map((i) => int.parse(i)).toList();
  final [bH, bM] = b.split(':').map((i) => int.parse(i)).toList();

  bool timeAfter = aH == bH ? aM > bM : aH > bH;
  return timeAfter;
}

bool isYMDInRange(DateTime date, DateTime start, DateTime end) =>
    (date.yearMonthDayEquals(start) || date.isYMDAfter(start)) &&
    (date.yearMonthDayEquals(end) || date.isYMDBefore(end));

bool isMDInRange(DateTime date, DateTime start, DateTime end,
        {bool dynamicYear = false}) =>
    (date.monthDayEquals(start) ||
        date.isMDAfter(start, dynamicYear ? null : date.year)) &&
    (date.monthDayEquals(end) ||
        date.isMDBefore(end, dynamicYear ? null : date.year));

bool isHMInRange(DateTime date, DateTime start, DateTime end) =>
    (date.hourMinuteEquals(start) || date.isAfter(start)) &&
    (date.hourMinuteEquals(end) || date.isBefore(end));

bool isHourMinuteInRange(
    String? time, String left, String right, String splitPattern) {
  time = time ?? DateTime.now().hmString;
  split(String string) => string.split(splitPattern).map(int.parse).toList();
  final format = DateTime(0);
  final timeSplit = split(time);
  final leftSplit = split(left);
  final rightSplit = split(right);

  final givenTime = DateTime(
      format.year, format.month, format.day, timeSplit[0], timeSplit[1]);
  final startTime = DateTime(
      format.year, format.month, format.day, leftSplit[0], leftSplit[1]);
  final endTime = DateTime(
      format.year, format.month, format.day, rightSplit[0], rightSplit[1]);

  return isHMInRange(givenTime, startTime, endTime);
}

DateTime dateStringToDate(String dateString, [final String pattern = '.']) {
  dateString = dateString.replaceAll(pattern, '.');
  final checked =
      dateString.split('.').map((it) => it.padLeft(2, '0')).toList();
  return DateTime.parse(checked.length == 3
      ? checked.join('-')
      : '${DateTime.now().year}-${checked.join('-')}');
}

List<DateTime> findDateTimes(
    DateTime start, DateTime end, bool Function(DateTime it) test) {
  var current = start;
  final result = <DateTime>[];
  while (true) {
    if (test(current)) result.add(current);
    if (current.year == end.year &&
        current.month == end.month &&
        current.day == end.day) {
      break;
    }
  }
  return result;
}

int getWeeks(DateTime start, DateTime end) {
  return (end.difference(start.subtract(const Duration(days: 1))).inDays / 7)
      .ceil();
}

Solar lunarToSolar(int year, int month, int day) =>
    Lunar.fromYmd(year, month, day).getSolar();

String lunarToDateString(int year, int month, int day) =>
    lunarToSolar(year, month, day).dateString;

Solar? getJieQi(DateTime date, String name) =>
    Lunar.fromDate(date).getJieQiTable()[name];

String? getSolarDurationDateString(Solar? start, int days) {
  if (start == null) return null;
  final end = start.nextDay(days - 1);
  return '${start.dateString}-${end.dateString}';
}

String getLunarDurationDateString(
    int year, int startMonth, int startDay, int days) {
  final start = Lunar.fromYmd(year, startMonth, startDay).getSolar();
  return getSolarDurationDateString(start, days + 1)!;
}

TimeOfDay timeStringToTimeOfDay(String time, {String pattern = ':'}) {
  final [hour, minute] = time.split(pattern).map((z) => int.parse(z)).toList();
  return TimeOfDay(hour: hour, minute: minute);
}

DateTime? tryParseDateTime(String? value) =>
    value == null ? null : DateTime.tryParse(value);

/// 仅供支持解析形如以下格式的字符串：
///
/// * 2025-01-01 08:00:00
/// * 2025-1-01 08:00:00
/// * 2025-01-1 08:00:00
/// * 2025-1-1 08:00:00
/// * 2025-01-01
/// * 2025-1-01
/// * 2025-01-1
/// * 2025-1-1
/// * 2025-01-01 9:00:00
/// * 2025-1-1 9:0:0
DateTime? tryParseFlexible(String? input) {
  if (input == null) return null;

  // 匹配带时间的格式: yyyy-M-d H:m:s
  final dateTimeRegex =
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2}) (\d{1,2}):(\d{1,2}):(\d{1,2})$');
  // 匹配仅日期格式: yyyy-M-d
  final dateOnlyRegex = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');

  final dateTimeMatch = dateTimeRegex.firstMatch(input);
  final dateOnlyMatch = dateOnlyRegex.firstMatch(input);

  if (dateTimeMatch != null) {
    // 解析带时间的格式
    String year = dateTimeMatch.group(1)!;
    String month = dateTimeMatch.group(2)!.padLeft(2, '0');
    String day = dateTimeMatch.group(3)!.padLeft(2, '0');
    String hour = dateTimeMatch.group(4)!.padLeft(2, '0'); // 补零
    String minute = dateTimeMatch.group(5)!.padLeft(2, '0'); // 补零
    String second = dateTimeMatch.group(6)!.padLeft(2, '0'); // 补零

    return DateTime.parse('$year-$month-$day $hour:$minute:$second');
  } else if (dateOnlyMatch != null) {
    // 解析仅日期的格式，补上时间 00:00:00
    String year = dateOnlyMatch.group(1)!;
    String month = dateOnlyMatch.group(2)!.padLeft(2, '0');
    String day = dateOnlyMatch.group(3)!.padLeft(2, '0');

    return DateTime.parse('$year-$month-$day 00:00:00');
  }

  return null;
}

String formatTimeDifference(TimeOfDay start, TimeOfDay end) {
  int startMinutes = start.hour * 60 + start.minute;
  int endMinutes = end.hour * 60 + end.minute;

  int diffMinutes = (endMinutes - startMinutes).abs();
  int hours = diffMinutes ~/ 60;
  int minutes = diffMinutes % 60;

  if (hours > 0 && minutes > 0) {
    return '$hours小时$minutes分钟';
  } else if (hours > 0) {
    return '$hours小时';
  } else if (minutes > 0) {
    return '$minutes分钟';
  } else {
    return '不到1分钟';
  }
}

extension DateTimeExtension on DateTime {
  DateTime get tomorrow => add(const Duration(days: 1));

  DateTime get yesterday => subtract(const Duration(days: 1));

  String get ymdString => '$year-${month.padL2}-${day.padL2}';

  String get dateString => '$year.${month.padL2}.${day.padL2}';

  String get hmString => '${hour.padL2}:${minute.padL2}';

  String get dateStringWithHM => '$dateString $hmString';

  String get string =>
      '$year-${month.padL2}-${day.padL2} ${hour.padL2}:${minute.padL2}:${second.padL2}';

  bool yearMonthDayEquals(DateTime other) =>
      other.year == year && monthDayEquals(other);

  bool monthDayEquals(DateTime other) =>
      other.month == month && other.day == day;

  bool hourMinuteEquals(DateTime other) =>
      other.hour == hour && other.minute == minute;

  bool isYMDAfter(DateTime other) => year >= other.year && isMDAfter(other);

  bool isYMDBefore(DateTime other) => year <= other.year && isMDBefore(other);

  bool isMDAfter(DateTime other, [int? year]) =>
      DateTime(year ?? DateTime.now().year, month, day).isAfter(
          DateTime(year ?? DateTime.now().year, other.month, other.day));

  bool isMDBefore(DateTime other, [int? year]) =>
      DateTime(year ?? DateTime.now().year, month, day).isBefore(
          DateTime(year ?? DateTime.now().year, other.month, other.day));

  bool operator >(DateTime other) => isAfter(other);

  bool operator >=(DateTime other) => this > other || this == other;

  bool operator <(DateTime other) => isBefore(other);

  bool operator <=(DateTime other) => this < other || this == other;

  Duration operator -(DateTime other) => difference(other);

  Duration differenceWithoutHMS(DateTime other) => DateTime(year, month, day)
      .difference(DateTime(other.year, other.month, other.day));
}

extension DurationExtension on Duration {
  int compareTo(Duration other) => this > other
      ? 1
      : this < other
          ? -1
          : 0;
}

extension SolarExtension on Solar {
  String get dateString => '${getYear()}.${getMonth().padL2}.${getDay().padL2}';
}

extension ObjectExtension on Object {
  String get padL2 => toString().padLeft(2, '0');
}

extension TimeOfDayExtension on TimeOfDay {
  String get hmString => '${hour.padL2}:${minute.padL2}';

  bool isAfter(TimeOfDay other) => hour > other.hour
      ? true
      : hour < other.hour
          ? false
          : minute > other.minute;

  bool isBefore(TimeOfDay other) => hour < other.hour
      ? true
      : hour > other.hour
          ? false
          : minute < other.minute;

  bool operator >(TimeOfDay other) => isAfter(other);

  bool operator >=(TimeOfDay other) => this > other || this == other;

  bool operator <(TimeOfDay other) => isBefore(other);

  bool operator <=(TimeOfDay other) => this < other || this == other;
}
