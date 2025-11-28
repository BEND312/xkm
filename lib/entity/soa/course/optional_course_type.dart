import 'package:hive/hive.dart';

part 'optional_course_type.g.dart';

@HiveType(typeId: 13)
enum OptionalCourseType {
  /// 网络通识课
  @HiveField(0)
  internetGeneralCourse,

  /// 素质选修课
  @HiveField(1)
  qualityOptionalCourse,

  /// 未知种类
  @HiveField(2)
  unknown;
}
