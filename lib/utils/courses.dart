import 'package:flutter/material.dart';
import 'package:swustmeow/entity/activity.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/time.dart';

import '../data/values.dart';
import '../entity/soa/course/course_entry.dart';
import '../entity/soa/course/courses_container.dart';

/// 获取课程周数
///
/// 如果 `current` 处在课程时段，返回 `(true, 周数)`；
/// 否则返回 `(false, 周数)`。
(bool, int) getWeekNum(String term, DateTime current) {
  final termDatesValue = GlobalService.termDates.value[term]?.value;
  final (begin, end, all) = termDatesValue ?? Values.getFallbackTermDates(term);
  final cur = getWeeks(begin, current);
  final inTerm = cur > 0 && cur <= all;
  return (inTerm, cur);
}

// TODO 优化 让所有课程根据名称集合为一个对象 避免分散
/// 获取相同名称的课程
List<CourseEntry> findSameCourses(
        CourseEntry course, List<CourseEntry> entries) =>
    entries.where((e) => e.courseName == course.courseName).toList()
      ..sort((a, b) => a.weekday.compareTo(b.weekday));

/// 判断课程是否已完成
bool checkIfFinished(
    String term, CourseEntry course, List<CourseEntry> entries) {
  final now = DateTime.now();
  final (i, w) = getWeekNum(term, now);
  final weekday = now.weekday;

  final allMatches = findSameCourses(course, entries)
    ..sort((a, b) => a.endWeek.compareTo(b.endWeek));
  final lastCourse = allMatches.lastOrNull ?? course;
  
  final time = Values.courseTableTimes[lastCourse.endSection != null
      ? lastCourse.endSection! % 2 == 0
          ? (lastCourse.endSection! / 2).toInt() - 1
          : ((lastCourse.endSection! + 1) / 2).toInt() - 1
      : lastCourse.numberOfDay - 1];

  if (w != lastCourse.endWeek) {
    return w > lastCourse.endWeek;
  }
  
  if (weekday != lastCourse.weekday) {
    return weekday > lastCourse.weekday;
  }
  
  return hmAfter('${now.hour}:${now.minute}', time.split('\n').last);
}

/// 获取剩余周数
int getWeeksRemaining(
    String term, CourseEntry course, List<CourseEntry> entries) {
  final allMatches = findSameCourses(course, entries)
    ..sort((a, b) => a.endWeek.compareTo(b.endWeek));
  final lastCourse = allMatches.lastOrNull ?? course;
  final now = DateTime.now();
  final (_, w) = getWeekNum(term, now);
  final base = (lastCourse.endWeek - w).abs();
  if (now.weekday < lastCourse.weekday) return base + 1;
  if (now.weekday > lastCourse.weekday) return base;

  final time = Values.courseTableTimes[lastCourse.numberOfDay - 1];
  return hmAfter('${now.hour}:${now.minute}', time.split('\n').last)
      ? base
      : base + 1;
}

/// 获取课程的（上课时间, 下课时间, 时间跨度字符串）
///
/// 时间跨度字符串示例：10:00-11:40
(String, String, String) getCourseTime(CourseEntry entry) {
  final times = <String>[];
  for (final t in Values.courseTableTimes) {
    for (final j in t.split('\n')) {
      times.add(j);
    }
  }

  final time = entry.startSection == null || entry.endSection == null
      ? Values.courseTableTimes[entry.numberOfDay - 1].replaceAll('\n', '-')
      : '${times[entry.startSection! - 1]}-${times[entry.endSection! - 1]}';
  final startTime = time.split('-').first;
  final endTime = time.split('-').last;

  return (startTime, endTime, time);
}

/// 根据当前时间获取要首先展示的课程表容器
///
/// 如，在寒假展示第一学期，在暑假展示第二学期。
///
/// 注意！必须保证 [containers] 参数至少包含一个 [CoursesContainer]
CoursesContainer getCurrentCoursesContainer(
    List<Activity> activities, List<CoursesContainer> containers) {
  final hs = activities.where((ac) => ac.name == '暑假' || ac.name == '寒假');
  final shu = hs.where((ac) => ac.name == '暑假').firstOrNull;
  final han = hs.where((ac) => ac.name == '寒假').firstOrNull;

  if (shu == null || han == null) return containers.first;
  if (shu.dateString == null || han.dateString == null) {
    return containers.first;
  }

  final [shuStart, shuEnd] =
      shu.dateString!.split('-').map((ds) => dateStringToDate(ds)).toList();
  final [hanStart, hanEnd] =
      han.dateString!.split('-').map((ds) => dateStringToDate(ds)).toList();

  final first = containers.where((c) => c.term.endsWith('上')).firstOrNull;
  final second = containers.where((c) => c.term.endsWith('下')).firstOrNull;
  if (first != null && second == null) return first;
  if (first == null && second != null) return second;

  final now = DateTime.now();

  // 如果当前在暑假或在寒假之前的秋季学期，展示第一学期
  if ((now.isAfter(shuStart) && now.isBefore(shuEnd)) ||
      (now.isAfter(shuEnd) && now.isBefore(hanStart))) {
    return first!;
  }

  // 如果当前在寒假或在暑假之前的春季学期，展示第二学期
  if ((now.isAfter(hanStart) && now.isBefore(hanEnd)) ||
      (now.isAfter(hanEnd) && now.isBefore(shuStart))) {
    return second!;
  }

  return containers.first;
}

/// 获取今天的所有课程、当前的课程以及下节课
///
/// 返回 (今天的所有课程列表, 当前课程, 下节课程)
(List<CourseEntry>, CourseEntry?, CourseEntry?) getCourse(
    String term, List<CourseEntry> entries) {
  if (entries.isEmpty) return ([], null, null);
  final now = DateTime.now();
  final (i, w) = getWeekNum(term, now);
  final todayEntries = entries
      .where((entry) =>
          i &&
          !checkIfFinished(term, entry, entries) &&
          entry.weekday == now.weekday &&
          w >= entry.startWeek &&
          w <= entry.endWeek)
      .toList()
    ..sort((a, b) => a.numberOfDay.compareTo(b.numberOfDay));

  CourseEntry? currentCourse;
  CourseEntry? nextCourse;

  for (int index = 0; index < todayEntries.length; index++) {
    final entry = todayEntries[index];
    final (s, e, _) = getCourseTime(entry);
    final startTime = timeStringToTimeOfDay(s);
    final endTime = timeStringToTimeOfDay(e);
    final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);

    if (startTime > nowTime && endTime > nowTime && nextCourse == null) {
      nextCourse = entry;
    }

    if (startTime <= nowTime && endTime >= nowTime) {
      currentCourse = entry;
    }
  }

  return (todayEntries, currentCourse, nextCourse);
}

/// 获取课程的时间和距离课程上课还有多久的文本
///
/// 返回 (课程的时间, 距离上课的差异时间文本)
(String, String) getCourseRemainingString(CourseEntry course) {
  final (startTime, _, time) = getCourseTime(course);
  final [startHour, startMinute] =
      startTime.split(':').map((c) => int.parse(c)).toList();
  final now = DateTime.now();
  final nowTod = TimeOfDay(hour: now.hour, minute: now.minute);
  final startTod = TimeOfDay(hour: startHour, minute: startMinute);
  final diff = formatTimeDifference(startTod, nowTod);
  return (time, diff);
}

Color getCourseScoreColor(String score) {
  score = score.trim();
  double? value = double.tryParse(score);
  if (value == null) return score == '通过' ? Colors.green : Colors.red;
  return value >= 60.0 ? Colors.green : Colors.red;
}
