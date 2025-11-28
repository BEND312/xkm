import 'package:hive/hive.dart';

import '../../../services/global_service.dart';
import '../../../services/value_service.dart';
import 'course_entry.dart';
import 'course_type.dart';

part 'courses_container.g.dart';

@HiveType(typeId: 10)
class CoursesContainer {
  CoursesContainer({
    required this.type,
    required this.term,
    required this.entries,
    this.id,
    this.remark,
  });

  /// 课程表类型，详见 [CourseType]
  @HiveField(0)
  final CourseType type;

  /// 课程表学期字符串
  ///
  /// 格式为：开始学年-结束学年-上/下，
  /// 如：2024-2025-上
  @HiveField(1)
  final String term;

  /// 课程表课程列表
  @HiveField(2)
  final List<CourseEntry> entries;

  /// 课程表ID
  @HiveField(3)
  final String? id;

  /// 分享者备注
  @HiveField(4)
  String? remark;

  int getWeeksNum() {
    final now = DateTime.now();
    final (_, _, w) =
        GlobalService.termDates.value[term]?.value ?? (now, now, -1);
    return w;
  }

  String parseDisplayString() {
    if (!term.contains('-') || term.split('-').length != 3) return '';
    final [s, e, t] = term.split('-');
    final w = getWeeksNum();
    final week = w > 0 ? '($w周)' : '';
    return '$s-$e-$t$week';
  }

  CoursesContainer get withCustomCourses => CoursesContainer(
        type: type,
        term: term,
        entries: entries + (ValueService.customCourses[id!] ?? []).cast(),
        id: id,
        remark: remark,
      );
}
