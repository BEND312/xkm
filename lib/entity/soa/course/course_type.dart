import 'package:hive/hive.dart';

part 'course_type.g.dart';

@HiveType(typeId: 9)
enum CourseType {
  /// 普通课程
  @HiveField(0)
  normal,

  /// 选课课程
  @HiveField(1)
  optional;
}
