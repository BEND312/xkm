import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:swustmeow/entity/base_event.dart';

import '../utils/time.dart';
import 'date_type.dart';
import 'activity_type.dart';

part 'activity.g.dart';

@JsonSerializable()
@HiveType(typeId: 3)
class Activity implements BaseEvent {
  const Activity(
      {this.name,
      required this.type,
      this.holiday = true,
      this.display = true,
      this.dateString,
      this.dateStringGetter,
      this.greetings,
      this.greetingsGetter});

  @HiveField(0)
  final String? name;

  @HiveField(1)
  final ActivityType type;

  /// 是否放假
  @HiveField(2)
  final bool holiday;

  /// 是否展示在日历中，通常为前夕此类设为 `false`
  @HiveField(3)
  final bool display;

  @HiveField(4)
  final String? dateString;

  /// 获取日期字符串的函数
  @JsonKey(includeToJson: false, includeFromJson: false)
  final String Function(DateTime date)? dateStringGetter;

  @HiveField(5)
  final List<String>? greetings;

  /// 获取问候语的函数
  @JsonKey(includeToJson: false, includeFromJson: false)
  final List<String> Function(DateTime date)? greetingsGetter;

  factory Activity.common(
          {required String name,
          bool holiday = false,
          bool display = true,
          String? dateString,
          String Function(DateTime date)? dateStringGetter,
          List<String>? greetings,
          List<String> Function(DateTime date)? greetingsGetter}) =>
      Activity(
          name: name,
          type: ActivityType.common,
          holiday: holiday,
          display: display,
          dateString: dateString,
          dateStringGetter: dateStringGetter,
          greetings: greetings,
          greetingsGetter: greetingsGetter);

  factory Activity.bigHoliday(
          {String? name,
          bool holiday = true,
          bool display = true,
          String? dateString,
          String Function(DateTime date)? dateStringGetter,
          List<String>? greetings,
          List<String> Function(DateTime date)? greetingsGetter}) =>
      Activity(
          name: name,
          type: ActivityType.bigHoliday,
          holiday: holiday,
          display: display,
          dateString: dateString,
          dateStringGetter: dateStringGetter,
          greetings: greetings,
          greetingsGetter: greetingsGetter);

  factory Activity.festival(
          {String? name,
          bool holiday = true,
          bool display = true,
          String? dateString,
          String Function(DateTime date)? dateStringGetter,
          List<String>? greetings,
          List<String> Function(DateTime date)? greetingsGetter}) =>
      Activity(
          name: name,
          type: ActivityType.festival,
          holiday: holiday,
          display: display,
          dateString: dateString,
          dateStringGetter: dateStringGetter,
          greetings: greetings,
          greetingsGetter: greetingsGetter);

  factory Activity.shift({
    String? dateString,
    String Function(DateTime date)? dateStringGetter,
  }) =>
      Activity(
        type: ActivityType.shift,
        holiday: false,
        dateString: dateString,
        dateStringGetter: dateStringGetter,
      );

  factory Activity.hidden({
    bool holiday = false,
    String? dateString,
    String Function(DateTime date)? dateStringGetter,
    List<String>? greetings,
    List<String> Function(DateTime date)? greetingsGetter,
  }) =>
      Activity(
          type: ActivityType.hidden,
          holiday: holiday,
          display: false,
          greetings: greetings,
          greetingsGetter: greetingsGetter);

  String? getDateString(DateTime date) {
    final tryGet = dateStringGetter == null ? null : dateStringGetter!(date);
    return tryGet ?? dateString;
  }

  (DateType, (DateTime?, DateTime?)) getDateRange(DateTime date) {
    final ds = getDateString(date);
    if (ds == null) return (DateType.none, (null, null));
    final split = ds.split('-');
    final startDateString = split.first;
    final endDateString = split.last;

    if (split.length == 2) {
      final startSplit = startDateString.split('.');
      final endSplit = endDateString.split('.');
      final sl = startSplit.length;
      final el = endSplit.length;

      // 特殊情况，如 2024.10.17-10.25
      // 解析为 2024.10.14 - 2024.10.25
      final fYear = sl == 3 ? startSplit.first : endSplit.first;
      if (sl == 3 && el == 2) {
        endSplit.insert(0, fYear);
      } else if (sl == 2 && el == 3) {
        startSplit.insert(0, fYear);
      }

      final parsedStart = dateStringToDate(startSplit.join('.'));
      final parsedEnd = dateStringToDate(endSplit.join('.'));

      return (
        sl == 2 && el == 2 ? DateType.dynamicMDRange : DateType.staticYMDRange,
        (parsedStart, parsedEnd)
      );
    }

    // 单个日期
    if (split.length == 1 || startDateString == endDateString) {
      final count = startDateString.split('.').length;
      final res = dateStringToDate(startDateString);
      return (count == 2 ? DateType.singleMD : DateType.singleYMD, (res, res));
    }

    return (DateType.none, (null, null));
  }

  bool get isFestival =>
      type == ActivityType.festival || type == ActivityType.bigHoliday;

  bool get isShift => type == ActivityType.shift;

  bool isInActivity(DateTime date) {
    final ds = getDateString(date);
    if (ds == null) return false;

    final (type, (start, end)) = getDateRange(date);
    switch (type) {
      case DateType.none:
        return false;
      case DateType.singleMD:
        return date.monthDayEquals(start!);
      case DateType.singleYMD:
        return date.yearMonthDayEquals(start!);
      case DateType.dynamicMDRange:
        return isMDInRange(date, start!, end!, dynamicYear: true);
      case DateType.staticYMDRange:
        return isYMDInRange(date, start!, end!);
    }
  }

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityToJson(this);

  @override
  String? getName() => name;

  @override
  DateTime? getStart(DateTime date) {
    final (_, (start, _)) = getDateRange(date);
    return start;
  }

  @override
  DateTime? getEnd(DateTime date) {
    final (_, (_, end)) = getDateRange(date);
    return end;
  }

  @override
  DateType getType(DateTime date) {
    final (type, (_, _)) = getDateRange(date);
    return type;
  }
}
