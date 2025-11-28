import 'package:hive/hive.dart';
import 'package:swustmeow/entity/soa/course/optional_task_type.dart';
import 'package:swustmeow/entity/soa/course/optional_course_type.dart';

part 'optional_course.g.dart';

@HiveType(typeId: 12)
class OptionalCourse {
  const OptionalCourse(
      {required this.cid,
      required this.name,
      required this.credit,
        required this.taskType,
      required this.courseType});

  @HiveField(0)
  final String cid;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double credit;

  @HiveField(3)
  final OptionalTaskType taskType;

  @HiveField(4)
  final OptionalCourseType courseType;
}
